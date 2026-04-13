import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/session_store.dart';
import '../../home/ui/guard_home_view.dart';
import '../data/auth_service.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/app_logo.dart';

class GuardLoginView extends StatefulWidget {
  const GuardLoginView({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<GuardLoginView> createState() => _GuardLoginViewState();
}

class _GuardLoginViewState extends State<GuardLoginView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    final authService = AuthService(
      context.read<ApiClient>(),
      context.read<SessionStore>(),
    );
    final result = await authService.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      deviceId: Env.deviceId,
    );
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    if (result.isSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GuardHomeView(cameras: widget.cameras),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.errorMessage ?? 'No se pudo iniciar sesion.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        loading: _loading,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo(width: 110, height: 110)),
                    const SizedBox(height: 24),
                    Text(
                      'Control Entradas DRT',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Usuario'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contrasena',
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _login,
                      child: const Text('Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
