import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vault/core/api/api_service.dart';
import 'package:vault/core/theme/vault_reveal.dart';
import 'package:vault/features/profile/profile_screen.dart';
import 'package:vault/features/settings/admin_settings_screen.dart';

void main() {
  final admin = {
    'id': 1,
    'custom_username': 'admin',
    'admin_status': true,
    'profile_type': 'standard',
    'account_status': 'active'
  };
  final user = {
    'id': 2,
    'custom_username': 'viewer',
    'admin_status': false,
    'profile_type': 'standard',
    'account_status': 'active'
  };
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
        appName: 'Vault',
        packageName: 'vault',
        version: '0.0.5',
        buildNumber: '3',
        buildSignature: 'test');
    await ApiService.setServerUrl('https://vault.example');
    ApiService.serverOnline.value = true;
  });
  testWidgets('profile separates admin shortcuts from regular users',
      (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: ProfileScreen(initialData: user)));
    await tester.pumpAndSettle();
    expect(find.text('CENTRO DE ADMINISTRACIÓN'), findsNothing);
    await tester.pumpWidget(
        MaterialApp(home: ProfileScreen(key: UniqueKey(), initialData: admin)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Publicar avisos'), 250);
    expect(find.text('Usuarios y acceso'), findsOneWidget);
    expect(find.text('Sincronizar IPTV'), findsOneWidget);
    ApiService.serverOnline.value = false;
    await tester.pumpAndSettle();
    final tile = tester.widget<ListTile>(find.ancestor(
        of: find.text('Publicar avisos'), matching: find.byType(ListTile)));
    expect(tile.onTap, isNull);
  });
  testWidgets('admin tabs search accounts and send profile updates using PUT',
      (tester) async {
    var changed = false;
    ApiService.transport = MockClient((request) async {
      if (request.url.path == '/health') {
        return http.Response('{"service":"vault"}', 200);
      }
      if (request.url.path == '/auth/login') {
        return http.Response('{"access_token":"test"}', 200);
      }
      if (request.url.path == '/auth/me') {
        return http.Response(jsonEncode(admin), 200);
      }
      if (request.url.path == '/admin/users') {
        return http.Response(
            jsonEncode([
              admin,
              {...user, 'profile_type': changed ? 'kids' : 'standard'}
            ]),
            200);
      }
      if (request.url.path == '/admin/users/2/profile-type') {
        expect(request.method, 'PUT');
        expect(jsonDecode(request.body), {'profile_type': 'kids'});
        changed = true;
      }
      return http.Response('{}', 200);
    });
    expect(
        await tester
            .runAsync(() => ApiService().login('admin', 'test-password')),
        isNull);
    await tester.pumpWidget(const MaterialApp(home: AdminSettingsScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'viewer');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Perfil infantil'), 180,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.text('Perfil infantil'));
    await tester.pumpAndSettle();
    expect(changed, true);
    expect(find.text('Cambiar a normal'), findsOneWidget);
    await tester.tap(find.text('Avisos'));
    await tester.pumpAndSettle();
    expect(find.text('Enviar aviso'), findsOneWidget);
    await tester.tap(find.text('Sistema'));
    await tester.pumpAndSettle();
    expect(find.text('Sincronizar ahora'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reduced motion renders content without an entrance tween',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: VaultReveal(child: Text('Vault')))));
    expect(find.text('Vault'), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
  });
}
