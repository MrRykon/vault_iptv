import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/api/api_service.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final username = TextEditingController();
  final password = TextEditingController();
  final api = ApiService();
  bool loading = false;
  bool obscure = true;
  String? error;
  @override
  void initState() {
    super.initState();
    api.checkServer();
  }

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (username.text.trim().isEmpty || password.text.isEmpty) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await api.login(username.text, password.text);
      if (!mounted) return;
      if (result == null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        setState(() => error = result);
      }
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'No se pudo iniciar sesión. Comprueba el servidor e inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> configureServer() async {
    final controller = TextEditingController(text: ApiService.baseUrl);
    final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Servidor Vault'),
              content: TextField(
                  controller: controller,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                      hintText: 'http://192.168.1.20:8000')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, controller.text),
                    child: const Text('Guardar'))
              ],
            ));
    if (value == null) return;
    try {
      await ApiService.setServerUrl(value);
      await api.checkServer();
    } on FormatException catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: SafeArea(
              child: Center(
                  child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/dragon_logo.png', height: 110),
                  const SizedBox(height: 16),
                  const Text('VAULT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 36,
                          letterSpacing: 8,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  const Text('Tu cine. Tu TV. Tu espacio.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60)),
                  const SizedBox(height: 32),
                  TextField(
                      controller: username,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: Icon(Icons.person_outline)),
                      textInputAction: TextInputAction.next),
                  const SizedBox(height: 16),
                  TextField(
                      controller: password,
                      obscureText: obscure,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) {
                        if (!loading) login();
                      },
                      decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => obscure = !obscure),
                              icon: Icon(obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined)))),
                  const SizedBox(height: 24),
                  FilledButton(
                      onPressed: loading ? null : login,
                      child: loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Iniciar sesión')),
                  if (error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(error!,
                            style:
                                const TextStyle(color: Colors.orangeAccent))),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<bool>(
                      valueListenable: ApiService.serverOnline,
                      builder: (context, online, _) => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    online
                                        ? Icons.cloud_done_outlined
                                        : Icons.cloud_off_outlined,
                                    size: 18,
                                    color: online
                                        ? Colors.greenAccent
                                        : Colors.orangeAccent),
                                const SizedBox(width: 8),
                                Text(online
                                    ? 'Servidor conectado'
                                    : 'Servidor desconectado')
                              ])),
                  if (!kIsWeb)
                    TextButton.icon(
                        onPressed: loading ? null : configureServer,
                        icon: const Icon(Icons.dns_outlined),
                        label: const Text('Configurar servidor')),
                  const SizedBox(height: 8),
                  const Text(
                      'Sin servidor puedes entrar con una cuenta validada antes en este dispositivo y usar las listas IPTV guardadas. El primer acceso necesita conexión.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white54)),
                ])),
      ))));
}
