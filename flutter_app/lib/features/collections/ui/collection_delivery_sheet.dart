import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/uppercase_text_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../models/collection_deliver_request.dart';
import '../../packages/ui/widgets/signature_pad.dart';

class CollectionDeliverySheet extends StatefulWidget {
  const CollectionDeliverySheet({
    super.key,
    required this.collectionId,
    required this.requesterName,
  });

  final int collectionId;
  final String requesterName;

  @override
  State<CollectionDeliverySheet> createState() =>
      _CollectionDeliverySheetState();
}

class _CollectionDeliverySheetState extends State<CollectionDeliverySheet> {
  final TextEditingController _deliveredToController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey<SignaturePadState> _signatureKey =
      GlobalKey<SignaturePadState>();
  bool _showValidation = false;
  bool _exporting = false;

  @override
  void dispose() {
    _deliveredToController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final signatureState = _signatureKey.currentState;
    final hasValidName = _deliveredToController.text.trim().isNotEmpty &&
        Validators.hasDetectedName(fullName: _deliveredToController.text);

    if (!hasValidName ||
        signatureState == null ||
        !signatureState.hasSignature) {
      setState(() => _showValidation = true);
      showAppFeedback(
        context,
        'Falta quien recibe la recolección o la firma.',
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
      CollectionDeliverRequest(
        collectionId: widget.collectionId,
        deliveredToName: _deliveredToController.text.trim(),
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
                'Entregar recolección',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Confirma quién la recoge y toma la firma final de la solicitud de ${widget.requesterName}.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.textSoft
                      : AppColors.midnight,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _deliveredToController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: const [UppercaseTextFormatter()],
                decoration: InputDecoration(
                  labelText: 'Quién recoge / paquetería',
                  errorText: _showValidation &&
                          _deliveredToController.text.trim().isEmpty
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
                  'La firma es obligatoria para cerrar la recolección.',
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
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.collectionAccent,
                  ),
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
