import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../data/collection_deliver_service.dart';
import '../data/collection_detail_service.dart';
import '../models/collection_deliver_request.dart';
import '../models/collection_detail.dart';
import 'collection_delivery_sheet.dart';

class CollectionDetailView extends StatefulWidget {
  const CollectionDetailView({
    super.key,
    required this.collectionId,
  });

  final int collectionId;

  @override
  State<CollectionDetailView> createState() => _CollectionDetailViewState();
}

class _CollectionDetailViewState extends State<CollectionDetailView> {
  CollectionDetail? _detail;
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

    final result = await context.read<CollectionDetailService>().fetchDetail(
          widget.collectionId,
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
        _error = result.errorMessage ?? 'No se pudo cargar la recoleccion.';
      }
    });
  }

  Future<void> _openDelivery() async {
    final detail = _detail;
    if (detail == null) {
      return;
    }

    final request = await showModalBottomSheet<CollectionDeliverRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => CollectionDeliverySheet(
        collectionId: detail.id,
        requesterName: detail.requesterName,
      ),
    );

    if (request == null || !mounted) {
      return;
    }

    final result =
        await context.read<CollectionDeliverService>().deliver(request);
    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      showAppFeedback(
        context,
        result.data ?? 'Recolección entregada correctamente.',
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
        'La entrega de la recolección sí quedó registrada.',
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
      appBar: AppBar(title: const Text('Detalle de recoleccion')),
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
                                  : AppColors.collectionAccent)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          detail.isDelivered
                              ? Icons.task_alt_rounded
                              : Icons.outbox_outlined,
                          color: detail.isDelivered
                              ? AppColors.success
                              : AppColors.collectionAccent,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.requesterName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              detail.isDelivered
                                  ? 'Recoleccion cerrada y firmada'
                                  : 'Recoleccion pendiente de entrega',
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
              _CollectionGallery(
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
                      _InfoRow(label: 'Solicitante', value: detail.hostName),
                      _InfoRow(label: 'Correo', value: detail.requesterEmail),
                      _InfoRow(
                        label: 'WhatsApp',
                        value: detail.requesterPhone.trim().isEmpty
                            ? 'Sin capturar'
                            : detail.requesterPhone,
                      ),
                      _InfoRow(
                        label: 'Vigilante',
                        value: detail.guardHandoverName.trim().isEmpty
                            ? 'Sin capturar'
                            : detail.guardHandoverName,
                      ),
                      _InfoRow(
                        label: 'Guia',
                        value: detail.trackingNumber.trim().isEmpty
                            ? 'Sin capturar'
                            : detail.trackingNumber,
                      ),
                      _InfoRow(
                        label: 'Recolector',
                        value: detail.carrierCompany.trim().isEmpty
                            ? 'No indicado'
                            : detail.carrierCompany,
                      ),
                      _InfoRow(
                        label: 'Registrado',
                        value: DateTimeFormatter.dateTime(detail.registeredAt),
                      ),
                      _InfoRow(
                        label: 'Notificacion',
                        value: detail.notificationSentAt != null
                            ? 'Enviada ${DateTimeFormatter.dateTime(detail.notificationSentAt)}'
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
              if (detail.delivery != null) ...[
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entrega',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          label: 'Recibio',
                          value: detail.delivery!.deliveredToName,
                        ),
                        _InfoRow(
                          label: 'Hora',
                          value: DateTimeFormatter.dateTime(
                            detail.delivery!.deliveredAt,
                          ),
                        ),
                        _InfoRow(
                          label: 'Notas',
                          value: detail.delivery!.deliveryNotes.isEmpty
                              ? 'Sin observaciones'
                              : detail.delivery!.deliveryNotes,
                          isLast: true,
                        ),
                        if (detail.delivery!.signatureBase64.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.borderSoft),
                            ),
                            child: Image.memory(
                              base64Decode(detail.delivery!.signatureBase64),
                              height: 180,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: detail != null && !detail.isDelivered
          ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SafeArea(
                top: false,
                child: FilledButton.icon(
                  onPressed: _openDelivery,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    backgroundColor: AppColors.collectionAccent,
                  ),
                  icon: const Icon(Icons.draw_outlined),
                  label: const Text('Entregar al recolector'),
                ),
              ),
            )
          : null,
    );
  }
}

class _CollectionGallery extends StatelessWidget {
  const _CollectionGallery({
    required this.detail,
    required this.selectedIndex,
    required this.onSelected,
  });

  final CollectionDetail detail;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedPhoto =
        detail.photos.isEmpty ? null : detail.photos[selectedIndex];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evidencia',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.4,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                clipBehavior: Clip.antiAlias,
                child: selectedPhoto == null
                    ? const Center(child: Text('Sin evidencia'))
                    : Image.memory(
                        base64Decode(selectedPhoto.imageBase64),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
              ),
            ),
            if (detail.photos.length > 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 82,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: detail.photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final photo = detail.photos[index];
                    return InkWell(
                      onTap: () => onSelected(index),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 92,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: index == selectedIndex
                                ? AppColors.collectionAccent
                                : AppColors.borderSoft,
                            width: index == selectedIndex ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.memory(
                          base64Decode(photo.imageBase64),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
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

  final CollectionDetail detail;

  @override
  Widget build(BuildContext context) {
    final color =
        detail.isDelivered ? AppColors.success : AppColors.collectionAccent;
    final label = detail.isDelivered ? 'Entregado' : 'Pendiente';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
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
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSoft
                        : AppColors.midnight,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
