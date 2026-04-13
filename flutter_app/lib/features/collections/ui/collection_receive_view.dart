import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/camera_selector.dart';
import '../../../core/utils/uppercase_text_formatter.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../guards/data/guard_service.dart';
import '../../guards/models/guard_item.dart';
import '../../hosts/models/host_item.dart';
import '../../hosts/ui/host_picker_sheet.dart';
import '../../packages/data/package_carrier_service.dart';
import '../../packages/models/package_carrier_item.dart';
import '../../packages/ui/package_capture_view.dart';
import '../models/collection_receive_request.dart';

class CollectionReceiveView extends StatefulWidget {
  const CollectionReceiveView({
    super.key,
    required this.cameras,
  });

  final List<CameraDescription> cameras;

  @override
  State<CollectionReceiveView> createState() => _CollectionReceiveViewState();
}

class _CollectionReceiveViewState extends State<CollectionReceiveView> {
  final TextEditingController _requesterManualController =
      TextEditingController();
  final TextEditingController _requesterEmailController =
      TextEditingController();
  final TextEditingController _requesterPhoneController =
      TextEditingController();
  final TextEditingController _trackingNumberController =
      TextEditingController();
  final TextEditingController _carrierManualController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  HostItem? _selectedHost;
  GuardItem? _selectedGuard;
  PackageCarrierItem? _selectedCarrier;
  List<GuardItem> _guards = const <GuardItem>[];
  List<PackageCarrierItem> _carriers = const <PackageCarrierItem>[];
  final List<String> _photos = <String>[];
  bool _guardsLoading = false;
  bool _carriersLoading = false;
  bool _showValidation = false;

  bool get _isManualRequester => _selectedHost?.isManual ?? false;
  bool get _needsManualCarrier =>
      (_selectedCarrier?.carrierName.trim().toUpperCase() ?? '') == 'OTRO';
  bool get _hasRequesterSelection => _selectedHost != null;
  bool get _contactFieldsReadOnly => _selectedHost != null && !_isManualRequester;

  @override
  void initState() {
    super.initState();
    _loadGuards();
    _loadCarriers();
  }

  @override
  void dispose() {
    _requesterManualController.dispose();
    _requesterEmailController.dispose();
    _requesterPhoneController.dispose();
    _trackingNumberController.dispose();
    _carrierManualController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadGuards() async {
    setState(() => _guardsLoading = true);
    final result = await context.read<GuardService>().fetchActive();
    if (!mounted) {
      return;
    }

    setState(() {
      _guardsLoading = false;
      _guards = result.data ?? const <GuardItem>[];
    });
  }

  Future<void> _loadCarriers() async {
    setState(() => _carriersLoading = true);
    final result = await context.read<PackageCarrierService>().fetchActive();
    if (!mounted) {
      return;
    }

    setState(() {
      _carriersLoading = false;
      _carriers = result.data ?? const <PackageCarrierItem>[];
    });
  }

  Future<void> _pickRequester() async {
    final host = await Navigator.of(context).push<HostItem>(
      MaterialPageRoute(
        builder: (_) => const HostPickerSheet(
          title: 'Elegir quien solicita',
          description:
              'Busca a la persona que solicitó la recolección. Si no aparece, usa OTRO para capturarla manualmente.',
          searchHint: 'Buscar solicitante',
        ),
      ),
    );
    if (host == null) {
      return;
    }

    setState(() {
      _selectedHost = host;
      _requesterManualController.text =
          host.isManual ? host.fullName.trim() : '';
      _requesterEmailController.text = host.email.trim();
      _requesterPhoneController.text = host.phoneNumber.trim();
    });
  }

  Future<void> _addPhoto() async {
    final preferredCamera = selectPreferredCamera(widget.cameras);
    if (preferredCamera == null) {
      showAppFeedback(
        context,
        'No se detectó cámara en este dispositivo.',
        tone: AppFeedbackTone.warning,
      );
      return;
    }

    final photo = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PackageCaptureView(camera: preferredCamera),
      ),
    );
    if (photo == null || !mounted) {
      return;
    }

    setState(() => _photos.add(photo));
  }

  void _removePhoto(String photo) {
    setState(() => _photos.remove(photo));
  }

  String _resolvedRequesterName() {
    if (_isManualRequester) {
      return _requesterManualController.text.trim();
    }
    return _selectedHost?.fullName.trim() ?? '';
  }

  String _validationMessage() {
    if (!_hasRequesterSelection) {
      return 'Falta elegir quién solicita la recolección.';
    }
    if (_resolvedRequesterName().isEmpty) {
      return 'Falta capturar el solicitante.';
    }
    if (_selectedGuard == null) {
      return 'Falta elegir el vigilante que entrega.';
    }
    if (_trackingNumberController.text.trim().isEmpty) {
      return 'Falta indicar la guía.';
    }
    if (_needsManualCarrier && _carrierManualController.text.trim().isEmpty) {
      return 'Falta capturar quién recolecta.';
    }
    if (_photos.isEmpty) {
      return 'Agrega al menos una foto para la recolección.';
    }
    return 'Revisa los datos de la recolección.';
  }

  Future<void> _submit() async {
    final valid = _hasRequesterSelection &&
        _resolvedRequesterName().isNotEmpty &&
        _selectedGuard != null &&
        _trackingNumberController.text.trim().isNotEmpty &&
        (!_needsManualCarrier ||
            _carrierManualController.text.trim().isNotEmpty) &&
        _photos.isNotEmpty;

    if (!valid) {
      setState(() => _showValidation = true);
      showAppFeedback(
        context,
        _validationMessage(),
        tone: AppFeedbackTone.warning,
      );
      return;
    }

    Navigator.of(context).pop(
      CollectionReceiveRequest(
        hostId: _selectedHost!.isManual ? null : _selectedHost!.id,
        requesterNameManual:
            _selectedHost!.isManual ? _resolvedRequesterName() : '',
        guardHandoverId: _selectedGuard!.id,
        requesterEmailOverride: _requesterEmailController.text.trim(),
        requesterPhoneOverride: _requesterPhoneController.text.trim(),
        trackingNumber: _trackingNumberController.text.trim(),
        carrierCompany: _selectedCarrier?.carrierName.trim() ?? '',
        carrierNameManual:
            _needsManualCarrier ? _carrierManualController.text.trim() : '',
        notes: _notesController.text.trim(),
        photos: List<String>.from(_photos),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar recolección')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salida a recolección',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Registra la solicitud, toma evidencia y cierra con firma cuando el recolector pase con guardias.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.brightness == Brightness.dark
                            ? AppColors.textSoft
                            : AppColors.midnight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              tileColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: _showValidation && !_hasRequesterSelection
                      ? theme.colorScheme.error
                      : AppColors.borderSoft,
                ),
              ),
              title: Text(_selectedHost?.fullName ?? 'Quién solicita'),
              subtitle: Text(
                _selectedHost == null
                    ? 'Selecciona a la persona o usa Otro'
                    : (_selectedHost!.isManual
                        ? 'Solicitante manual'
                        : (_selectedHost!.email.trim().isEmpty
                            ? 'Sin correo guardado'
                            : _selectedHost!.email.trim())),
                style: _showValidation && !_hasRequesterSelection
                    ? TextStyle(color: theme.colorScheme.error)
                    : null,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _pickRequester,
            ),
            if (_isManualRequester) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _requesterManualController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: const [UppercaseTextFormatter()],
                decoration: InputDecoration(
                  labelText: 'Solicitante manual',
                  errorText: _showValidation &&
                          _requesterManualController.text.trim().isEmpty
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                onChanged: (_) {
                  if (_showValidation) {
                    setState(() {});
                  }
                },
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _requesterEmailController,
              readOnly: _contactFieldsReadOnly,
              decoration: InputDecoration(
                labelText: 'Correo del solicitante (opcional)',
                helperText: _contactFieldsReadOnly
                    ? 'Dato tomado del anfitrión seleccionado.'
                    : null,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _requesterPhoneController,
              readOnly: _contactFieldsReadOnly,
              decoration: InputDecoration(
                labelText: 'WhatsApp del solicitante (opcional)',
                helperText: _contactFieldsReadOnly
                    ? 'Dato tomado del anfitrión seleccionado.'
                    : null,
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            if (_guardsLoading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text('Cargando vigilantes...')),
                  ],
                ),
              )
            else
              DropdownButtonFormField<GuardItem>(
                initialValue: _selectedGuard,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Vigilante que entrega',
                  errorText: _showValidation && _selectedGuard == null
                      ? 'Selecciona un vigilante'
                      : null,
                ),
                items: _guards
                    .map(
                      (guard) => DropdownMenuItem<GuardItem>(
                        value: guard,
                        child: Text(
                          guard.fullName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _guards.isEmpty
                    ? null
                    : (guard) => setState(() => _selectedGuard = guard),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _trackingNumberController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: const [UppercaseTextFormatter()],
              decoration: InputDecoration(
                labelText: 'Guía',
                errorText: _showValidation &&
                        _trackingNumberController.text.trim().isEmpty
                    ? 'Este dato es obligatorio'
                    : null,
              ),
              onChanged: (_) {
                if (_showValidation) {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 12),
            if (_carriersLoading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                        child: Text('Cargando catálogo de recolectores...')),
                  ],
                ),
              )
            else
              DropdownButtonFormField<PackageCarrierItem>(
                initialValue: _selectedCarrier,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Recolector / quién lo lleva',
                ),
                items: _carriers
                    .map(
                      (carrier) => DropdownMenuItem<PackageCarrierItem>(
                        value: carrier,
                        child: Text(
                          carrier.carrierName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _carriers.isEmpty
                    ? null
                    : (carrier) => setState(() => _selectedCarrier = carrier),
              ),
            if (_needsManualCarrier) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _carrierManualController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: const [UppercaseTextFormatter()],
                decoration: InputDecoration(
                  labelText: 'Quién recolecta (manual)',
                  errorText: _showValidation &&
                          _carrierManualController.text.trim().isEmpty
                      ? 'Este dato es obligatorio'
                      : null,
                ),
                onChanged: (_) {
                  if (_showValidation) {
                    setState(() {});
                  }
                },
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: const [UppercaseTextFormatter()],
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                hintText: 'EJ. SALE HOY, PASA DHL 4 PM',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Fotos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Agregar foto'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_photos.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _showValidation && _photos.isEmpty
                        ? theme.colorScheme.error
                        : AppColors.borderSoft,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_camera_back_outlined,
                      color: _showValidation && _photos.isEmpty
                          ? theme.colorScheme.error
                          : AppColors.collectionAccent,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Toma al menos una foto como evidencia de la recolección.',
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 122,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return Stack(
                      children: [
                        Container(
                          width: 142,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderSoft),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.memory(
                              base64Decode(photo),
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () => _removePhoto(photo),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xCC0B1426),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SafeArea(
          top: false,
          child: FilledButton.icon(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              backgroundColor: AppColors.collectionAccent,
            ),
            icon: const Icon(Icons.outbox_outlined),
            label: const Text('Guardar recolección'),
          ),
        ),
      ),
    );
  }
}
