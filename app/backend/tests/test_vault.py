"""Functional checks use isolated SQLite, catalogs and releases; no production data."""
import asyncio
import importlib.util
import os
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import AsyncMock, patch

state = tempfile.TemporaryDirectory()
ROOT = Path(state.name)
os.environ['DATABASE_URL'] = f'sqlite:///{ROOT / "vault.db"}'
os.environ['PLAYLISTS_DIR'] = str(ROOT / 'playlists')
os.environ['RELEASES_DIR'] = str(ROOT / 'releases')
os.environ['SEED_ADMIN_ON_FIRST_RUN'] = 'false'
os.environ['SECRET_KEY'] = 'isolated-test-key-not-for-deployment'
os.environ['IPTV_SOURCE_URL'] = ''
os.environ['MOCK_PLEX'] = 'true'
(ROOT / 'playlists').mkdir()

from fastapi.testclient import TestClient
from app.main import app
from app.db.database import SessionLocal
from app.db.models import User, IPTVChannelCache
from app.core.security import get_password_hash
from app.services import iptv_service
from app.core.config import settings

TOOLS = Path(__file__).resolve().parents[2] / 'tools'
def tool(name):
    spec = importlib.util.spec_from_file_location(name, TOOLS / f'{name}.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class VaultTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with SessionLocal() as db:
            db.add(User(custom_username='admin', hashed_password=get_password_hash('test-admin'), admin_status=True, account_status='active', profile_type='standard'))
            db.add(User(custom_username='viewer', hashed_password=get_password_hash('test-viewer'), admin_status=False, account_status='active', profile_type='standard'))
            db.add(User(custom_username='child', hashed_password=get_password_hash('test-child'), admin_status=False, account_status='active', profile_type='kids'))
            db.commit()
        cls.client = TestClient(app)
    def token(self, user='admin'):
        response = self.client.post('/auth/login', data={'username': user, 'password': f'test-{user}'})
        self.assertEqual(response.status_code, 200)
        return {'Authorization': 'Bearer ' + response.json()['access_token']}

    def test_login_roles_and_private_registration(self):
        self.assertEqual(self.client.get('/health').json()['service'], 'vault')
        self.assertEqual(self.client.get('/auth/me').status_code, 401)
        self.assertEqual(self.client.get('/vod/scan').status_code, 401)
        self.assertEqual(self.client.post('/auth/login', data={'username':'admin','password':'wrong'}).status_code, 401)
        self.assertEqual(self.client.post('/auth/register', json={'custom_username':'unauthorized','password':'password'}).status_code, 403)
        user = self.token('viewer')
        self.assertEqual(self.client.get('/vod/scan', headers=user).status_code, 403)
        self.assertEqual(self.client.get('/admin/users', headers=user).status_code, 403)
        self.assertEqual(self.client.post('/notifications/', params={'subject':'x','content':'x'}, headers=user).status_code, 403)
        admin = self.token()
        self.assertEqual(self.client.get('/auth/me', headers=admin).json()['admin_status'], True)
        response = self.client.post('/admin/users', headers=admin, json={'custom_username':'new-user','password':'new-password','profile_type':'standard'})
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.json()['admin_status'])
        self.assertEqual(self.client.post('/notifications/', params={'subject':'Aviso','content':'Hola'}, headers=admin).status_code, 200)
        self.assertEqual(self.client.get('/notifications/', headers=user).json()[0]['content'], 'Hola')
        self.client.post('/auth/logout', headers=user)
        self.assertEqual(self.client.get('/auth/me', headers=user).status_code, 401)

    def test_expiration_is_utc_and_enforced_after_sqlite_roundtrip(self):
        from datetime import datetime, timedelta, timezone
        from app.services.auth_service import create_access_token
        with SessionLocal() as db:
            user = User(custom_username='expired',hashed_password=get_password_hash('expired-password'),account_status='active',profile_type='standard',admin_status=False,access_expires_at=datetime.now(timezone.utc)+timedelta(days=1))
            db.add(user);db.commit();db.refresh(user)
            token = create_access_token(db,user.id)
            headers = {'Authorization':'Bearer '+token}
            expiry = self.client.get('/auth/me',headers=headers).json()['access_expires_at']
            self.assertTrue(expiry.endswith('Z') or expiry.endswith('+00:00'))
            user.access_expires_at = datetime.now(timezone.utc)-timedelta(days=1)
            db.commit()
        self.assertEqual(self.client.post('/auth/login',data={'username':'expired','password':'expired-password'}).status_code,403)
        self.assertEqual(self.client.get('/auth/me',headers=headers).status_code,403)

    def test_m3u_attribute_order_and_group_filter(self):
        text = '#EXTM3U\n#EXTINF:-1 group-title="Kids, Family" tvg-name="Cartoon" tvg-id="1",Other title\nhttps://example.org/one.m3u8\n'
        channel = list(iptv_service.parse_m3u(text))[0]
        self.assertEqual(channel['channel_name'], 'Cartoon')
        self.assertEqual(channel['category'], 'Kids, Family')
        self.assertTrue(channel['is_kids_safe'])
        self.assertEqual(list(iptv_service.parse_m3u('#EXTM3U\n#EXTINF:-1,Unsafe\nfile:///secret\n')), [])

    def test_playlist_add_edit_delete_and_bad_file_preserves_catalog(self):
        path = ROOT / 'playlists' / 'fixture.m3u'
        async def run():
            with SessionLocal() as db:
                iptv_service.sync_status['revision'] = ''
                path.write_text('#EXTM3U\n#EXTINF:-1 group-title="Kids",First\nhttps://example.org/first\n')
                self.assertTrue(await iptv_service.sync_iptv_channels(db))
                self.assertEqual(db.query(IPTVChannelCache).count(), 1)
                child = self.token('child')
                self.assertEqual(len(self.client.get('/iptv/channels', headers=child).json()), 1)
                path.write_text('#EXTM3U\n#EXTINF:-1 group-title="News",Second\nhttps://example.org/second\n')
                self.assertTrue(await iptv_service.sync_iptv_channels(db))
                self.assertEqual(db.query(IPTVChannelCache).one().channel_name, 'Second')
                self.assertEqual(self.client.get('/iptv/channels', headers=child).json(), [])
                path.write_text('not a playlist')
                self.assertFalse(await iptv_service.sync_iptv_channels(db))
                self.assertEqual(db.query(IPTVChannelCache).one().channel_name, 'Second')
                path.unlink()
                self.assertTrue(await iptv_service.sync_iptv_channels(db))
                self.assertEqual(db.query(IPTVChannelCache).count(), 0)
        asyncio.run(run())

    def test_plex_placeholder_and_child_restriction(self):
        self.assertEqual(len(self.client.get('/plex/library', headers=self.token()).json()), 3)
        self.assertEqual(len(self.client.get('/plex/library', headers=self.token('child')).json()), 1)
        self.assertEqual(self.client.get('/plex/stream/1', headers=self.token()).status_code, 409)

    def test_real_plex_adapter_catalog_children_and_range_stream_with_mock_server(self):
        import httpx
        original_client = httpx.AsyncClient
        movie = {'ratingKey':'10','title':'Movie','type':'movie','Genre':[{'tag':'Family'}],'thumb':'/library/metadata/10/thumb/1','Media':[{'Part':[{'key':'/library/parts/10/file.mp4'}]}]}
        show = {'ratingKey':'20','title':'Show','type':'show','Genre':[{'tag':'Family'}]}
        def handler(request):
            self.assertEqual(request.headers.get('X-Plex-Token'), 'private-test-token')
            path = request.url.path
            if path == '/library/sections': return httpx.Response(200,json={'MediaContainer':{'Directory':[{'key':'1','type':'movie'},{'key':'2','type':'show'}]}})
            if path.endswith('/1/all'): return httpx.Response(200,json={'MediaContainer':{'Metadata':[movie]}})
            if path.endswith('/2/all'): return httpx.Response(200,json={'MediaContainer':{'Metadata':[show]}})
            if path.endswith('/20/children'): return httpx.Response(200,json={'MediaContainer':{'Metadata':[{'ratingKey':'21','title':'Season 1','type':'season'}]}})
            if path == '/library/metadata/20': return httpx.Response(200,json={'MediaContainer':{'Metadata':[show]}})
            if path == '/library/metadata/10': return httpx.Response(200,json={'MediaContainer':{'Metadata':[movie]}})
            if path.startswith('/library/parts/'):
                self.assertEqual(request.headers.get('Range'), 'bytes=0-3')
                return httpx.Response(206,stream=httpx.ByteStream(b'part'),headers={'content-type':'video/mp4','content-range':'bytes 0-3/4','accept-ranges':'bytes'})
            if path == '/library/metadata/10/thumb/1':return httpx.Response(200,content=b'image',headers={'content-type':'image/jpeg'})
            return httpx.Response(404)
        transport = httpx.MockTransport(handler)
        with patch.object(settings,'MOCK_PLEX',False), patch.object(settings,'PLEX_BASE_URL','https://plex.example'), patch.object(settings,'PLEX_TOKEN','private-test-token'), patch('httpx.AsyncClient',side_effect=lambda **kwargs: original_client(transport=transport, **kwargs)):
            auth = self.token('child')
            catalog = self.client.get('/plex/library',headers=auth)
            self.assertEqual([item['type'] for item in catalog.json()], ['movie','show'])
            self.assertNotIn('private-test-token',catalog.text)
            self.assertEqual(self.client.get('/plex/children/20',headers=auth).json()[0]['type'],'season')
            response=self.client.get('/plex/stream/10',headers={**auth,'Range':'bytes=0-3'})
            self.assertEqual(response.status_code,206)
            self.assertEqual(response.content,b'part')
            self.assertEqual(response.headers['content-range'],'bytes 0-3/4')
            self.assertEqual(self.client.get('/plex/image',params={'url':'/library/metadata/10/thumb/1'},headers=auth).content,b'image')
            self.assertEqual(self.client.get('/plex/image',params={'url':'//evil.example'},headers=auth).status_code,400)

    def test_xtream_catalog_and_episodes(self):
        async def call(origin, credentials, action=None, series_id=None):
            if action is None: return {'user_info':{'auth':1,'status':'Active'}}
            if action == 'get_series_info': return {'episodes':{'1':[{'id':2,'title':'Episode','container_extension':'mp4'}]}}
            return [{'stream_id':1,'series_id':3,'name':'Test','container_extension':'mp4'}]
        payload = {'server':'https://provider.example','username':'name','password':'secret','section':'live'}
        with patch('app.api.xtream.provider_origin', AsyncMock(return_value='https://provider.example')), patch('app.api.xtream.provider_call', call):
            result = self.client.post('/xtream/catalog', headers=self.token(), json=payload)
            self.assertEqual(result.status_code, 200)
            self.assertEqual(result.json()['items'][0]['stream_url'], 'https://provider.example/live/name/secret/1.m3u8')
            result = self.client.post('/xtream/episodes', headers=self.token(), json={**payload,'series_id':3})
            self.assertEqual(result.json()['items'][0]['stream_url'], 'https://provider.example/series/name/secret/2.mp4')
            self.assertEqual(self.client.post('/xtream/catalog', headers=self.token('child'), json=payload).status_code, 403)
        self.assertEqual(self.client.post('/xtream/catalog', headers=self.token(), json={**payload,'server':'http://127.0.0.1'}).status_code, 400)

    def test_ota_missing_valid_corrupt_and_monotonic_build(self):
        root = ROOT / 'releases'
        self.assertEqual(self.client.get('/updates/check').json(), {'available':False})
        apk = ROOT / 'fixture.apk'
        with zipfile.ZipFile(apk, 'w') as archive:
            archive.writestr('AndroidManifest.xml', 'synthetic unit-test fixture; not an installable APK')
        publisher = tool('publish_update')
        publisher.publish(apk, '0.1.0', 1, root=root)
        response = self.client.get('/updates/check')
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()['available'])
        url = response.json()['apk_download_url']
        self.assertEqual(self.client.get(url).content, apk.read_bytes())
        with self.assertRaises(ValueError): publisher.publish(apk, '0.1.1', 1, root=root)
        (root / 'Vault_0.1.0+1.apk').write_bytes(b'corrupted')
        self.assertEqual(self.client.get('/updates/check').status_code, 503)
        self.assertEqual(self.client.get('/updates/apk/../../anything').status_code, 404)

    def test_launcher_detects_changes_and_increments_build_without_editing_pubspec(self):
        from unittest.mock import Mock
        launcher = tool('server')
        publisher = tool('publish_update')
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            frontend = root / 'frontend'
            for name in ('lib', 'assets', 'android', 'build/app/outputs/flutter-apk'):
                (frontend / name).mkdir(parents=True, exist_ok=True)
            (root / 'playlists').mkdir()
            (frontend / 'android/key.properties').write_text('unit test config')
            (frontend / 'pubspec.yaml').write_text('version: 0.1.0+1')
            (frontend / 'pubspec.lock').write_text('test lock')
            source = frontend / 'lib/main.dart'
            source.write_text('first')
            calls = []
            def fake_run(command, **kwargs):
                calls.append(command)
                if command[1:3] == ['build', 'web']:
                    (frontend/'build/web').mkdir(exist_ok=True)
                    (frontend/'build/web/index.html').write_text('compiled')
                if command[1:3] == ['build', 'apk']:
                    with zipfile.ZipFile(frontend/'build/app/outputs/flutter-apk/app-release.apk', 'w') as apk:
                        apk.writestr('AndroidManifest.xml','unit-test fixture')
                return Mock(returncode=0)
            with patch.object(launcher, 'APP', root), patch.object(launcher, 'FRONTEND', frontend), patch.object(launcher.shutil, 'which', return_value='flutter'), patch.object(launcher.subprocess, 'run', side_effect=fake_run), patch.dict('sys.modules', {'publish_update':publisher}):
                launcher.refresh_build()
                count = len(calls)
                launcher.refresh_build()
                self.assertEqual(len(calls), count)
                source.write_text('second')
                launcher.refresh_build()
                self.assertIn('--build-number=2', calls[-1])
                self.assertEqual((frontend/'pubspec.yaml').read_text(), 'version: 0.1.0+1')
                import json
                self.assertEqual(json.loads((root/'releases/release.json').read_text())['latest_build'], 2)

    def test_maintenance_preserves_user_data(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ('backend/vault.db','backend/.env','playlists/user.m3u','releases/Vault_1.0.0+1.apk','frontend/lib/main.dart','frontend/build/junk','backend/app/__pycache__/cache.pyc'):
                path = root / name; path.parent.mkdir(parents=True, exist_ok=True); path.write_text('keep')
            cleaner = tool('maintenance')
            cleaner.clean(root, dry_run=True)
            self.assertTrue((root/'frontend/build/junk').exists())
            cleaner.clean(root)
            self.assertFalse((root/'frontend/build').exists())
            for name in ('backend/vault.db','backend/.env','playlists/user.m3u','releases/Vault_1.0.0+1.apk','frontend/lib/main.dart'):
                self.assertTrue((root/name).exists())

if __name__ == '__main__': unittest.main()
