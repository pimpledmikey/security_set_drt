import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/uppercase_text_formatter.dart';
import '../data/host_service.dart';
import '../models/host_item.dart';

class HostPickerSheet extends StatefulWidget {
  const HostPickerSheet({
    super.key,
    this.title = 'Elegir anfitrion',
    this.description =
        'Busca por nombre o area para encontrar rapido a la persona.',
    this.searchHint = 'Buscar anfitrion',
    this.allowManualEntry = true,
    this.manualEntryLabel = 'OTRO',
  });

  final String title;
  final String description;
  final String searchHint;
  final bool allowManualEntry;
  final String manualEntryLabel;

  @override
  State<HostPickerSheet> createState() => _HostPickerSheetState();
}

class _HostPickerSheetState extends State<HostPickerSheet> {
  final TextEditingController _controller = TextEditingController();
  List<HostItem> _hosts = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final result = await context.read<HostService>().search(query);
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _hosts = result.data ?? const [];
    });
  }

  Future<void> _openManualHostDialog() async {
    final nameController = TextEditingController(text: _controller.text.trim());
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    final host = await showDialog<HostItem>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Capturar persona manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: const [UppercaseTextFormatter()],
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej. JUAN PEREZ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Correo (opcional)',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'WhatsApp (opcional)',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                return;
              }

              Navigator.of(dialogContext).pop(
                HostItem.manual(
                  fullName: name,
                  email: emailController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                ),
              );
            },
            child: const Text('Usar este nombre'),
          ),
        ],
      ),
    );

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    if (host != null && mounted) {
      Navigator.of(context).pop(host);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.textSoft
                      : AppColors.midnight,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.trim().isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _controller.clear();
                            _search('');
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
                onChanged: (value) {
                  setState(() {});
                  _search(value);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount:
                            _hosts.length + (widget.allowManualEntry ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (widget.allowManualEntry && index == 0) {
                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              tileColor: theme.colorScheme.primary.withValues(
                                alpha: 0.08,
                              ),
                              title: Text(widget.manualEntryLabel),
                              subtitle: Text(
                                _controller.text.trim().isEmpty
                                    ? 'Si no aparece en la lista, capturalo manualmente.'
                                    : 'Usar "${_controller.text.trim()}" o escribir otro nombre.',
                              ),
                              trailing: const Icon(Icons.edit_note_rounded),
                              onTap: _openManualHostDialog,
                            );
                          }

                          final host =
                              _hosts[index - (widget.allowManualEntry ? 1 : 0)];

                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            tileColor: theme.colorScheme.surface,
                            title: Text(host.fullName),
                            subtitle: Text(
                              [
                                if (host.email.trim().isNotEmpty)
                                  host.email.trim(),
                                if (host.phoneNumber.trim().isNotEmpty)
                                  host.phoneNumber.trim(),
                                if (host.areaName.trim().isNotEmpty)
                                  host.areaName.trim(),
                                if (host.email.trim().isEmpty &&
                                    host.phoneNumber.trim().isEmpty &&
                                    host.areaName.trim().isEmpty)
                                  'Sin correo, telefono ni area',
                              ].join(' • '),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.of(context).pop(host),
                          );
                        },
                      ),
              ),
              if (!_loading && _hosts.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: Text(
                      'No se encontraron anfitriones.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.brightness == Brightness.dark
                            ? AppColors.textSoft
                            : AppColors.midnight,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
