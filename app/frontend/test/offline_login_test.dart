import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vault/core/api/api_service.dart';
import 'package:vault/core/services/offline_account.dart';
import 'package:vault/features/auth/login_screen.dart';
import 'package:vault/features/home/home_screen.dart';
import 'package:vault/features/iptv/iptv_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  final profile = {
    'id': 1,
    'custom_username': 'viewer',
    'display_name': 'Viewer',
    'admin_status': false,
    'profile_type': 'standard',
    'account_status': 'active'
  };
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    ApiService.transport = MockClient((request) async {
      if (request.url.path == '/health') {
        return http.Response('{"service":"vault"}', 200);
      }
      if (request.url.path == '/auth/login') {
        return http.Response('{"access_token":"test-token"}', 200);
      }
      if (request.url.path == '/auth/me') {
        return http.Response(jsonEncode(profile), 200);
      }
      if (request.url.path == '/iptv/channels') {
        return http.Response(
            '[{"channel_id":"one","channel_name":"One","stream_url":"https://example.org/live"}]',
            200);
      }
      return http.Response('{}', 200);
    });
    await ApiService.setServerUrl('https://vault.example');
    await api.logout();
  });
  test(
      'offline login verifies saved password and keeps the per-account catalog',
      () async {
    expect(await api.login('viewer', 'correct-password'), isNull);
    expect(await api.getIptvChannels(), hasLength(1));
    await api.logout();
    ApiService.transport =
        MockClient((_) async => throw http.ClientException('offline'));
    expect(await api.login('viewer', 'wrong-password'), isNotNull);
    expect(await api.login('new-user', 'correct-password'), isNotNull);
    expect(await api.login('viewer', 'correct-password'), isNull);
    expect(ApiService.serverOnline.value, false);
    expect((await api.getProfile())?['custom_username'], 'viewer');
    expect((await api.getIptvChannels())?.first['channel_id'], 'one');
  });
  test(
      'authoritative rejection removes offline access rather than falling back',
      () async {
    expect(await api.login('viewer', 'correct-password'), isNull);
    ApiService.transport = MockClient((request) async =>
        http.Response('{"detail":"Account suspended"}', 403));
    expect(await api.getProfile(), isNull);
    expect(ApiService.sessionRejected, true);
    expect(await api.getToken(), isNull);
    expect(
        await OfflineAccount.verify(
            ApiService.baseUrl, 'viewer', 'correct-password'),
        isNull);
  });
  test('changing server cannot reuse credentials from another server',
      () async {
    expect(await api.login('viewer', 'correct-password'), isNull);
    await ApiService.setServerUrl('https://another.example');
    ApiService.transport =
        MockClient((_) async => throw http.ClientException('offline'));
    expect(await api.login('viewer', 'correct-password'), isNotNull);
  });
  test(
      'IPTV reuses ETag catalogue and rejects revoked access without cached fallback',
      () async {
    expect(await api.login('viewer', 'correct-password'), isNull);
    var calls = 0;
    ApiService.transport = MockClient((request) async {
      calls++;
      if (calls == 1) {
        return http.Response('[{"channel_id":"one","channel_name":"One"}]', 200,
            headers: {'etag': '"revision-one"'});
      }
      expect(request.headers['If-None-Match'], '"revision-one"');
      return http.Response('', 304);
    });
    expect((await api.getIptvChannels())?.first['channel_id'], 'one');
    expect((await api.getIptvChannels())?.first['channel_id'], 'one');
    ApiService.transport = MockClient((_) async => http.Response('{}', 403));
    expect(await api.getIptvChannels(), isNull);
    expect(ApiService.sessionRejected, true);
    expect(await api.getToken(), isNull);
    expect(
        await OfflineAccount.verify(
            ApiService.baseUrl, 'viewer', 'correct-password'),
        isNull);
  });
  testWidgets('large IPTV catalogues build visible rows and filter favorites',
      (tester) async {
    expect(await tester.runAsync(() => api.login('viewer', 'correct-password')),
        isNull);
    ApiService.transport = MockClient((_) async => http.Response(
        jsonEncode(List.generate(
            1000,
            (i) => {
                  'channel_id': 'channel-$i',
                  'channel_name': 'Channel $i',
                  'category': i.isEven ? 'News' : 'Kids',
                  'stream_url': 'https://example.org/$i',
                  'is_kids_safe': i.isOdd,
                })),
        200));
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: IptvScreen())));
    await tester.pumpAndSettle();
    expect(find.text('1000 canales'), findsOneWidget);
    expect(find.text('Channel 999'), findsNothing);
    expect(find.byType(ListTile).evaluate().length, lessThan(30));
    await tester.tap(find.byTooltip('Agregar a favoritos').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();
    expect(find.text('1 canales'), findsOneWidget);
    expect(find.text('Channel 0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('launch shows login and server controls immediately',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Configurar servidor'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });
  testWidgets(
      'home has Plex cards, admin notices, center Live TV and isolated Xtream',
      (tester) async {
    await tester.runAsync(() => api.login('viewer', 'correct-password'));
    ApiService.transport = MockClient((request) async {
      if (request.url.path == '/auth/me') {
        return http.Response(jsonEncode(profile), 200);
      }
      if (request.url.path == '/plex/library') {
        return http.Response(
            '[{"id":"mock","title":"Demo movie","type":"movie","mock":true}]',
            200);
      }
      if (request.url.path == '/notifications/') {
        return http.Response(
            '[{"subject":"Aviso","content":"Bienvenido"}]', 200);
      }
      if (request.url.path == '/iptv/channels') {
        return http.Response(
            '[{"channel_id":"one","channel_name":"Canal uno","stream_url":"https://example.org/live"}]',
            200);
      }
      return http.Response('{}', 200);
    });
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Demo movie'), findsOneWidget);
    expect(find.text('Aviso\nBienvenido'), findsOneWidget);
    expect(find.text('Live TV'), findsOneWidget);
    expect(find.text('Xtream'), findsOneWidget);
    await tester.tap(find.text('Live TV'));
    await tester.pumpAndSettle();
    expect(find.text('Canal uno'), findsOneWidget);
    await tester.tap(find.text('Xtream'));
    await tester.pumpAndSettle();
    expect(find.text('Xtream Codes'), findsOneWidget);
    ApiService.serverOnline.value = false;
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Xtream requiere el servidor Vault conectado. Puedes seguir usando Live TV.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
