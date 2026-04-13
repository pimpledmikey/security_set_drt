import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../data/package_deliver_service.dart';
import '../data/package_detail_service.dart';
import '../models/package_detail.dart';
import '../models/package_deliver_request.dart';
import 'package_delivery_sheet.dart';

class PackageDetailView extends StatefulWidget {
  const PackageDetailView({
    super.key,
    required this.packageId,
  });

  final int packageId;

  @override
  State<PackageDetailView> createState() => _PackageDetailViewState();
}

class _PackageDetailViewState extends State<PackageDetailView> {
  PackageDetail? _detail;
  bool _loading = true;
  String? _error;
  int _selectedPhotoIndex = 0;

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

    final result = await context.read<PackageDetailService>().fetchDetail(
          widget.packageId,
        );
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      if (result.data != null) {
        _detail = result.data!;
        final primaryIndex =
            _detail!.photos.indexWhere((photo) => photo.isPrimary);
        _selectedPhotoIndex = primaryIndex >= 0 ? primaryIndex : 0;
      } else {
        _error = result.errorMessage ?? 'No se pudo cargar el paquete.';
      }
    });
  }

  Future<void> _openDelivery() async {
    final detail = _detail;
    if (detail == null) {
      return;
    }

    final request = await showModalBottomSheet<PackageDeliverRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => PackageDeliverySheet(
        packageId: detail.id,
        recipientName: detail.recipientName,
      ),
    );

    if (request == null || !mounted) {
      return;
    }

    final result = await context.read<PackageDeliverService>().deliver(request);
    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      showAppFeedback(
        context,
        result.data ?? 'Paquete entregado correctamente.',
        tone: AppFeedbackTone.success,
      );
      await _load();
      return;
    }

    await _load();
    if (!mounted) {
      return;
    }
    if (_detail?.isDelivered ?? false) {
      showAppFeedback(
        context,
        'La entrega del paquete sí quedó registrada.',
        tone: AppFeedbackTone.success,
      );
      return;
    }

    showAppFeedback(
      context,
      result.errorMessage ?? 'No se pudo cerrar la entrega.',
      tone: AppFeedbackTone.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = _detail;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del paquete')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            if (_error != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (detail == null && _loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (detail != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: (detail.isDelivered
                                  ? AppColors.success
                                  : AppColors.packageAccent)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          detail.isDelivered
                              ? Icons.task_alt_rounded
                              : Icons.inventory_2_outlined,
                          color: detail.isDelivered
                              ? AppColors.success
                              : AppColors.packageAccent,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.recipientName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              detail.isDelivered
                                  ? 'Recepcion cerrada y firmada'
                                  : 'Paquete pendiente de entrega',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.brightness == Brightness.dark
                                    ? AppColors.textSoft
                                    : AppColors.midnight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusPill(detail: detail),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _PackageGallery(
                detail: detail,
                selectedIndex: _selectedPhotoIndex,
                onSelected: (index) =>
                    setState(() => _selectedPhotoIndex = index),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _InfoRow(label: 'Para quien es', value: detail.hostName),
                      _InfoRow(label: 'Correo', value: detail.recipientEmail),
                      _InfoRow(
                        label: 'WhatsApp',
                        value: detail.recipientPhone.trim().isEmpty
                            ? 'Sin capturar'
                            : detail.recipientPhone,
                      ),
                      _InfoRow(
                        label: 'Vigilante',
                        value: detail.guardReceivedName.trim().isEmpty
                            ? 'Sin capturar'
                            : detail.guardReceivedName,
                      ),
                      _InfoRow(
                        label: 'Numero de guia',
                        value: detail.trackingNumber.trim().isEmpty
                            ? 'Sin capturar'
                            : detail.trackingNumber,
                      ),
                      _InfoRow(
                        label: 'Paqueteria',
                        value: detail.carrierCompany.isEmpty
                            ? 'No indicada'
                            : detail.carrierCompany,
                      ),
                      _InfoRow(
                        label: 'Cantidad',
                        value: detail.packageCount == 1
                            ? '1 paquete'
                            : '${detail.packageCount} paquetes',
                      ),
                      _InfoRow(
                        label: 'Recibido',
                        value: DateTimeFormatter.dateTime(detail.receivedAt),
                      ),
                      _InfoRow(
                        label: 'Notificacion',
                        value: detail.isNotified
                            ? 'Enviada ${DateTimeFormatter.dateTime(detail.notifiedAt)}'
                            : 'Pendiente',
                      ),
                      _InfoRow(
                        label: 'Observaciones',
                        value: detail.notes.isEmpty
                            ? 'Sin observaciones'
                            : detail.notes,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (detail.notificationStatus == 'FAILED')
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            detail.notificationMessage.isEmpty
                                ? 'La notificacion no se pudo enviar.'
                                : detail.notificationMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (detail.delivery != null) ...[
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entrega firmada',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(
                          label: 'Recibio',
                          value: detail.delivery!.receivedByName,
                        ),
                        _InfoRow(
                          label: 'Hora de entrega',
                          value: DateTimeFormatter.dateTime(
                            detail.delivery!.deliveredAt,
                          ),
                        ),
                        _InfoRow(
                          label: 'Observaciones',
                          value: detail.delivery!.deliveryNotes.isEmpty
                              ? 'Sin observaciones'
                              : detail.delivery!.deliveryNotes,
                          isLast: true,
                        ),
                        const SizedBox(height: 14),
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderSoft),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _SafeBase64Image(
                              base64Image: detail.delivery!.signatureBase64,
                              fit: BoxFit.contain,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (!detail.isDelivered) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _openDelivery,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    backgroundColor: AppColors.packageAccent,
                  ),
                  icon: const Icon(Icons.draw_outlined),
                  label: const Text('Entregar paquete'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _PackageGallery extends StatelessWidget {
  const _PackageGallery({
    required this.detail,
    required this.selectedIndex,
    required this.onSelected,
  });

  final PackageDetail detail;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photos = detail.photos;

    if (photos.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(
                Icons.photo_camera_back_outlined,
                color: AppColors.packageAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No hay fotos disponibles para esta recepcion.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final activeIndex = selectedIndex >= photos.length ? 0 : selectedIndex;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _SafeBase64Image(
                    base64Image: photos[activeIndex].imageBase64,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            if (photos.length > 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    final selected = index == activeIndex;
                    return InkWell(
                      onTap: () => onSelected(index),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 92,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? AppColors.packageAccent
                                : AppColors.borderSoft,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _SafeBase64Image(
                            base64Image: photo.imageBase64,
                            fit: BoxFit.cover,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.detail});

  final PackageDetail detail;

  @override
  Widget build(BuildContext context) {
    final color = detail.isDelivered
        ? AppColors.success
        : detail.isNotified
            ? AppColors.packageAccent
            : AppColors.warning;
    final label = detail.isDelivered
        ? 'Entregado'
        : detail.isNotified
            ? 'Notificado'
            : 'Pendiente';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? AppColors.textSoft
                    : AppColors.midnight,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafeBase64Image extends StatelessWidget {
  const _SafeBase64Image({
    required this.base64Image,
    this.fit = BoxFit.cover,
    this.width,
    this.padding = const EdgeInsets.all(12),
  });

  final String base64Image;
  final BoxFit fit;
  final double? width;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeBytes(base64Image);
    if (bytes == null) {
      return const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.textSoft,
          size: 34,
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Image.memory(
        bytes,
        width: width,
        fit: fit,
        gaplessPlayback: true,
      ),
    );
  }

  Uint8List? _decodeBytes(String value) {
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }
}
