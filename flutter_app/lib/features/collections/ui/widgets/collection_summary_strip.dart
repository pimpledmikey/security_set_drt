import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class CollectionSummaryStrip extends StatelessWidget {
  const CollectionSummaryStrip({
    super.key,
    required this.pendingReceipts,
    required this.deliveredReceipts,
  });

  final int pendingReceipts;
  final int deliveredReceipts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CollectionMetricCard(
            label: 'Pendientes',
            value: pendingReceipts.toString(),
            helper: pendingReceipts == 1
                ? '1 recoleccion por entregar'
                : '$pendingReceipts recolecciones por entregar',
            icon: Icons.local_shipping_outlined,
            color: AppColors.collectionAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CollectionMetricCard(
            label: 'Entregados hoy',
            value: deliveredReceipts.toString(),
            helper: deliveredReceipts == 1
                ? '1 recoleccion cerrada'
                : '$deliveredReceipts recolecciones cerradas',
            icon: Icons.task_alt_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _CollectionMetricCard extends StatelessWidget {
  const _CollectionMetricCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? AppColors.textSoft
                    : AppColors.midnight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              helper,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? AppColors.textSoft
                    : AppColors.midnight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
