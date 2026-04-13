import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/theme_controller.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../bootstrap/data/bootstrap_service.dart';
import '../../bootstrap/models/bootstrap_payload.dart';
import '../data/app_settings_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _packageEmailEnabled = false;
  bool _packageWhatsappEnabled = false;
  bool _collectionEmailEnabled = false;
  bool _collectionWhatsappEnabled = false;
  bool _visitEmailEnabled = false;
  bool _visitWhatsappEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await context.read<BootstrapService>().load();
    if (!mounted) {
      return;
    }

    if (result.data != null) {
      final BootstrapPayload payload = result.data!;
      setState(() {
        _loading = false;
        _packageEmailEnabled = payload.packageEmailEnabled;
        _packageWhatsappEnabled = payload.packageWhatsappEnabled;
        _collectionEmailEnabled = payload.collectionEmailEnabled;
        _collectionWhatsappEnabled = payload.collectionWhatsappEnabled;
        _visitEmailEnabled = payload.visitEmailEnabled;
        _visitWhatsappEnabled = payload.visitWhatsappEnabled;
      });
      return;
    }

    setState(() {
      _loading = false;
      _error = result.errorMessage ?? 'No se pudo cargar la configuracion.';
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result =
        await context.read<AppSettingsService>().updateNotificationSettings(
              packageEmailEnabled: _packageEmailEnabled,
              packageWhatsappEnabled: _packageWhatsappEnabled,
              collectionEmailEnabled: _collectionEmailEnabled,
              collectionWhatsappEnabled: _collectionWhatsappEnabled,
              visitEmailEnabled: _visitEmailEnabled,
              visitWhatsappEnabled: _visitWhatsappEnabled,
            );

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);
    showAppFeedback(
      context,
      result.isSuccess
          ? 'Configuración actualizada.'
          : (result.errorMessage ?? 'No se pudo actualizar la configuración.'),
      tone: result.isSuccess ? AppFeedbackTone.success : AppFeedbackTone.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final isDark = controller.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuracion')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_error != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SwitchListTile(
                  value: isDark,
                  title: const Text('Tema Midnight Blue'),
                  subtitle: const Text('Desactivalo para usar la vista clara.'),
                  onChanged: (_) => controller.toggle(),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _packageWhatsappEnabled,
                        title: const Text('WhatsApp de paquetes'),
                        subtitle: const Text(
                          'Canal principal. Envia aviso por WhatsApp al destinatario del paquete.',
                        ),
                        onChanged: (value) {
                          setState(() => _packageWhatsappEnabled = value);
                        },
                      ),
                      const Divider(height: 0),
                      SwitchListTile(
                        value: _packageEmailEnabled,
                        title: const Text('Correo de paquetes'),
                        subtitle: const Text(
                          'Respaldo. Se usa si WhatsApp no puede enviarse o no hay número.',
                        ),
                        onChanged: (value) {
                          setState(() => _packageEmailEnabled = value);
                        },
                      ),
                      const Divider(height: 0),
                      SwitchListTile(
                        value: _collectionWhatsappEnabled,
                        title: const Text('WhatsApp de recoleccion'),
                        subtitle: const Text(
                          'Canal principal. Envia aviso por WhatsApp al solicitante cuando la recolección se entregue.',
                        ),
                        onChanged: (value) {
                          setState(() => _collectionWhatsappEnabled = value);
                        },
                      ),
                      const Divider(height: 0),
                      SwitchListTile(
                        value: _collectionEmailEnabled,
                        title: const Text('Correo de recoleccion'),
                        subtitle: const Text(
                          'Respaldo. Se usa si WhatsApp no puede enviarse o no hay número.',
                        ),
                        onChanged: (value) {
                          setState(() => _collectionEmailEnabled = value);
                        },
                      ),
                      const Divider(height: 0),
                      SwitchListTile(
                        value: _visitWhatsappEnabled,
                        title: const Text('WhatsApp de visitas'),
                        subtitle: const Text(
                          'Canal principal. Envia aviso por WhatsApp a la persona que recibirá la visita.',
                        ),
                        onChanged: (value) {
                          setState(() => _visitWhatsappEnabled = value);
                        },
                      ),
                      const Divider(height: 0),
                      SwitchListTile(
                        value: _visitEmailEnabled,
                        title: const Text('Correo de visitas'),
                        subtitle: const Text(
                          'Respaldo. Se usa si WhatsApp no puede enviarse o no hay número.',
                        ),
                        onChanged: (value) {
                          setState(() => _visitEmailEnabled = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
                ),
              ],
            ),
    );
  }
}
