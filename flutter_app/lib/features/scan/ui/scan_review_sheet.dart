import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/uppercase_text_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../hosts/models/host_item.dart';
import '../../hosts/ui/host_picker_sheet.dart';
import '../../visits/models/checkin_request.dart';
import '../models/extract_result.dart';

class ScanReviewSheet extends StatefulWidget {
  const ScanReviewSheet({super.key, required this.initialResult});

  final ExtractResult initialResult;

  @override
  State<ScanReviewSheet> createState() => _ScanReviewSheetState();
}

class _ScanReviewSheetState extends State<ScanReviewSheet> {
  late final TextEditingController _fullNameController;
  final TextEditingController _hostManualController = TextEditingController();
  final TextEditingController _hostEmailManualController =
      TextEditingController();
  final TextEditingController _hostPhoneManualController =
      TextEditingController();
  final TextEditingController _observationsController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  HostItem? _selectedHost;
  bool? _hasAppointment;
  bool _showValidation = false;
  int _groupSize = 1;

  bool get _isManualHost => _selectedHost?.isManual ?? false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.initialResult.fullName,
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _hostManualController.dispose();
    _hostEmailManualController.dispose();
    _hostPhoneManualController.dispose();
    _observationsController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _pickHost() async {
    final host = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<HostItem>(
      MaterialPageRoute(
        builder: (_) => const HostPickerSheet(
          title: 'Elegir anfitrion',
          description:
              'Busca a la persona a la que viene a ver. Si no aparece, usa OTRO para capturarla manualmente.',
          searchHint: 'Buscar anfitrion',
        ),
      ),
    );
    if (host == null) {
      return;
    }

    setState(() {
      _selectedHost = host;
      _hostManualController.text = host.isManual ? host.fullName.trim() : '';
      _hostEmailManualController.text = host.isManual ? host.email.trim() : '';
      _hostPhoneManualController.text =
          host.isManual ? host.phoneNumber.trim() : '';
    });
  }

  Future<bool> _confirmSinglePerson() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar cantidad'),
        content: const Text(
          'Se registrará solo 1 persona en esta visita. Si vienen más, regresa y ajusta la cantidad.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Regresar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    return approved == true;
  }

  String _resolvedHostName() {
    if (_isManualHost) {
      return _hostManualController.text.trim();
    }
    return _selectedHost?.fullName.trim() ?? '';
  }

  double _completionProgress() {
    var completed = 0;
    if (_fullNameController.text.trim().isNotEmpty) {
      completed += 1;
    }
    if (_resolvedHostName().isNotEmpty) {
      completed += 1;
    }
    if (_purposeController.text.trim().isNotEmpty) {
      completed += 1;
    }
    if (_hasAppointment != null) {
      completed += 1;
    }
    return completed / 4;
  }

  String _validationMessage() {
    if (_fullNameController.text.trim().isEmpty) {
      return 'Falta el nombre.';
    }
    if (_selectedHost == null) {
      return 'Falta elegir con quién viene.';
    }
    if (_resolvedHostName().isEmpty) {
      return 'Falta capturar el anfitrión.';
    }
    if (_purposeController.text.trim().isEmpty) {
      return 'Falta indicar a qué viene.';
    }
    if (_hasAppointment == null) {
      return 'Falta indicar si tiene cita.';
    }
    return 'Revisa los datos requeridos.';
  }

  Future<void> _submit() async {
    final valid = Validators.hasRequiredCheckInFields(
      fullName: _fullNameController.text,
      hostId: _selectedHost?.isManual == true ? null : _selectedHost?.id,
      hostNameManual: _resolvedHostName(),
      purpose: _purposeController.text,
      hasAppointment: _hasAppointment,
    );
    if (!valid) {
      setState(() => _showValidation = true);
      showAppFeedback(
        context,
        _validationMessage(),
        tone: AppFeedbackTone.warning,
      );
      return;
    }

    if (_groupSize == 1) {
      final confirmed = await _confirmSinglePerson();
      if (!confirmed || !mounted) {
        return;
      }
    }

    Navigator.of(context).pop(
      CheckInRequest(
        fullName: _fullNameController.text.trim(),
        identifierType: widget.initialResult.identifierType,
        identifierValue: widget.initialResult.identifierValue.trim(),
        documentLabel: widget.initialResult.documentLabel.trim(),
        birthDate: widget.initialResult.birthDate,
        hostId: _selectedHost?.isManual == true ? null : _selectedHost?.id,
        hostNameManual:
            _selectedHost?.isManual == true ? _resolvedHostName() : '',
        hostEmailManual: _selectedHost?.isManual == true
            ? _hostEmailManualController.text.trim()
            : '',
        hostPhoneManual: _selectedHost?.isManual == true
            ? _hostPhoneManualController.text.trim()
            : '',
        purpose: _purposeController.text.trim(),
        hasAppointment: _hasAppointment,
        groupSize: _groupSize,
        observations: _observationsController.text.trim(),
        documentImageBase64: widget.initialResult.documentImageBase64,
        documentImageMimeType: widget.initialResult.documentImageMimeType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _completionProgress();

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.initialResult.documentImageBase64.isNotEmpty) ...[
                  Container(
                    height: 184,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.04)
                          : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.memory(
                          base64Decode(
                            widget.initialResult.documentImageBase64,
                          ),
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Confirmar visita',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Completa los datos requeridos antes de guardar la entrada.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.textSoft
                        : AppColors.midnight,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Avance del registro',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Text('${(progress * 100).round()}%'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Campos necesarios',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: const [UppercaseTextFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    errorText: _showValidation &&
                            _fullNameController.text.trim().isEmpty
                        ? 'El nombre es obligatorio'
                        : null,
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  tileColor: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: _showValidation && _selectedHost == null
                          ? theme.colorScheme.error
                          : AppColors.borderSoft,
                    ),
                  ),
                  title: Text(_selectedHost?.fullName ?? 'Elegir anfitrión'),
                  subtitle: Text(
                    _selectedHost != null
                        ? (_selectedHost!.isManual
                            ? 'Anfitrión manual'
                            : (_selectedHost!.areaName.trim().isEmpty
                                ? 'Anfitrión seleccionado'
                                : _selectedHost!.areaName))
                        : (_showValidation && _selectedHost == null
                            ? 'El anfitrión es obligatorio'
                            : 'Toca para buscar o usar Otro'),
                    style: _showValidation && _selectedHost == null
                        ? TextStyle(color: theme.colorScheme.error)
                        : null,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickHost,
                ),
                if (_isManualHost) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hostManualController,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: const [UppercaseTextFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Anfitrión manual',
                      errorText: _showValidation &&
                              _hostManualController.text.trim().isEmpty
                          ? 'El anfitrión es obligatorio'
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hostEmailManualController,
                    decoration: const InputDecoration(
                      labelText: 'Correo anfitrión (opcional)',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hostPhoneManualController,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp anfitrión (opcional)',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _purposeController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: const [UppercaseTextFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Motivo de la visita',
                    hintText: 'EJ. ENTREGA DE DOCUMENTACION',
                    errorText: _showValidation &&
                            _purposeController.text.trim().isEmpty
                        ? 'El motivo es obligatorio'
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Text(
                  '¿Tiene cita?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _showValidation && _hasAppointment == null
                          ? theme.colorScheme.error
                          : AppColors.borderSoft,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _AppointmentOption(
                          label: 'Sí',
                          selected: _hasAppointment == true,
                          onTap: () => setState(() => _hasAppointment = true),
                        ),
                      ),
                      Expanded(
                        child: _AppointmentOption(
                          label: 'No',
                          selected: _hasAppointment == false,
                          onTap: () => setState(() => _hasAppointment = false),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showValidation && _hasAppointment == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona si la visita tiene cita.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Total de personas en esta visita',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Incluye al visitante principal. Si viene con 4 mas, elige 5.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.textSoft
                        : AppColors.midnight,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _groupSize > 1
                            ? () => setState(() => _groupSize -= 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '$_groupSize',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _groupSize == 1 ? 'Persona' : 'Personas',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _groupSize < 20
                            ? () => setState(() => _groupSize += 1)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Datos del documento',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _ReadOnlyField(
                  label: 'Dato identificador',
                  value: widget.initialResult.identifierValue.trim().isEmpty
                      ? 'Sin dato'
                      : widget.initialResult.identifierValue.trim(),
                ),
                const SizedBox(height: 12),
                _ReadOnlyField(
                  label: 'Tipo de documento',
                  value: widget.initialResult.documentLabel.trim().isEmpty
                      ? 'Identificación'
                      : widget.initialResult.documentLabel.trim(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Datos opcionales',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _observationsController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: const [UppercaseTextFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Observaciones (opcional)',
                    hintText: 'EJ. TRAE LAPTOP O EQUIPO',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Confirmar entrada'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSoft,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentOption extends StatelessWidget {
  const _AppointmentOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected
                  ? theme.colorScheme.primary
                  : (theme.brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.midnight),
            ),
          ),
        ),
      ),
    );
  }
}
