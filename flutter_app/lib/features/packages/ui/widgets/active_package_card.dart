import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../models/active_package_item.dart';

class ActivePackageCard extends StatelessWidget {
  const ActivePackageCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onDeliver,
  });

  final ActivePackageItem item;
  final VoidCallback onTap;
  final VoidCallback? onDeliver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = item.isDelivered
        ? AppColors.success
        : item.isNotified
            ? AppColors.packageAccent
            : AppColors.warning;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Icon(
                  item.isDelivered
                      ? Icons.task_alt_rounded
                      : Icons.inventory_2_outlined,
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.recipientName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.hostName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.brightness == Brightness.dark
                                      ? AppColors.textSoft
                                      : AppColors.midnight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _PackageStatusPill(
                          label: item.isDelivered
                              ? 'Entregado'
                              : item.isNotified
                                  ? 'Notificado'
                                  : 'Pendiente',
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.inventory_2_outlined,
                          label: item.packageCount == 1
                              ? '1 paquete'
                              : '${item.packageCount} paquetes',
                        ),
                        _InfoChip(
                          icon: Icons.photo_library_outlined,
                          label: item.photoCount == 1
                              ? '1 foto'
                              : '${item.photoCount} fotos',
                        ),
                        _InfoChip(
                          icon: Icons.qr_code_2_rounded,
                          label: item.trackingNumber.trim().isEmpty
                              ? 'Sin guía'
                              : item.trackingNumber,
                        ),
                        _InfoChip(
                          icon: Icons.security_outlined,
                          label: item.guardReceivedName.trim().isEmpty
                              ? 'Sin vigilante'
                              : item.guardReceivedName,
                        ),
                        _InfoChip(
                          icon: Icons.schedule_rounded,
                          label: item.isDelivered
                              ? 'Entregado ${DateTimeFormatter.shortTime(item.deliveredAt)}'
                              : 'Recibido ${DateTimeFormatter.shortTime(item.receivedAt)}',
                        ),
                      ],
                    ),
                    if (item.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        item.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.brightness == Brightness.dark
                              ? AppColors.textSoft
                              : AppColors.midnight,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onTap,
                            icon:
                                const Icon(Icons.visibility_outlined, size: 18),
                            label: const Text('Ver detalle'),
                          ),
                        ),
                        if (onDeliver != null) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onDeliver,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.packageAccent,
                              ),
                              icon: const Icon(Icons.draw_outlined, size: 18),
                              label: const Text('Entregar'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.brightness == Brightness.dark
                ? AppColors.packageSoft
                : AppColors.packageAccent,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageStatusPill extends StatelessWidget {
  const _PackageStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
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
