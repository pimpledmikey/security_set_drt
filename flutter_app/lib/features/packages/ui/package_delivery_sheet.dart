import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/uppercase_text_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../hosts/models/host_item.dart';
import '../../hosts/ui/host_picker_sheet.dart';
import '../models/package_deliver_request.dart';
import 'widgets/signature_pad.dart';

class PackageDeliverySheet extends StatefulWidget {
  const PackageDeliverySheet({
    super.key,
    required this.packageId,
    required this.recipientName,
  });

  final int packageId;
  final String recipientName;

  @override
  State<PackageDeliverySheet> createState() => _PackageDeliverySheetState();
}

class _PackageDeliverySheetState extends State<PackageDeliverySheet> {
  final TextEditingController _receivedByController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey<SignaturePadState> _signatureKey =
      GlobalKey<SignaturePadState>();
  bool _showValidation = false;
  bool _exporting = false;

  @override
  void dispose() {
    _receivedByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickReceiverHost() async {
    final host = await Navigator.of(context).push<HostItem>(
      MaterialPageRoute(
        builder: (_) => const HostPickerSheet(
          title: 'Elegir quien recibe',
          description:
              'Tambien puedes elegir desde el directorio de anfitriones para llenar el nombre mas rapido.',
          searchHint: 'Buscar persona que recoge',
        ),
      ),
    );
    if (host == null || !mounted) {
      return;
    }

    setState(() {
      _receivedByController.text = host.fullName.trim();
    });
  }

  Future<void> _submit() async {
    final signatureState = _signatureKey.currentState;
    final hasValidName = _receivedByController.text.trim().isNotEmpty &&
        Validators.hasDetectedName(fullName: _receivedByController.text);

    if (!hasValidName ||
        signatureState == null ||
        !signatureState.hasSignature) {
      setState(() => _showValidation = true);
      showAppFeedback(
        context,
        'Falta el nombre de quien recoge o la firma.',
        tone: AppFeedbackTone.warning,
      );
      return;
    }

    setState(() => _exporting = true);
    final signatureBase64 = await signatureState.exportAsBase64();
    if (!mounted) {
      return;
    }
    setState(() => _exporting = false);

    Navigator.of(context).pop(
      PackageDeliverRequest(
        packageId: widget.packageId,
        receivedByName: _receivedByController.text.trim(),
        signatureBase64: signatureBase64,
        deliveryNotes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entregar paquete',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Confirma quien lo recoge y toma la firma final del paquete de ${widget.recipientName}.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.textSoft
                      : AppColors.midnight,
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                tileColor: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: AppColors.borderSoft),
                ),
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Elegir desde anfitriones'),
                subtitle: const Text(
                  'Llena rapido el nombre de quien recoge desde el catalogo.',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _pickReceiverHost,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _receivedByController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: const [UppercaseTextFormatter()],
                decoration: InputDecoration(
                  labelText: 'Nombre de quien recoge',
                  errorText: _showValidation &&
                          _receivedByController.text.trim().isEmpty
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                onChanged: (_) {
                  if (_showValidation) {
                    setState(() {});
                  }
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _notesController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: const [UppercaseTextFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Observaciones de entrega (opcional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'Firma',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _signatureKey.currentState?.clear(),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Limpiar'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SignaturePad(key: _signatureKey),
              ),
              if (_showValidation &&
                  !(_signatureKey.currentState?.hasSignature ?? false)) ...[
                const SizedBox(height: 8),
                Text(
                  'La firma es obligatoria para cerrar la entrega.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _exporting ? null : _submit,
                  icon: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _exporting ? 'Procesando firma...' : 'Confirmar entrega',
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
