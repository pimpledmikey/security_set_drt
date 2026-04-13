import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class PackageSummaryStrip extends StatelessWidget {
  const PackageSummaryStrip({
    super.key,
    required this.pendingReceipts,
    required this.pendingPieces,
    required this.deliveredReceipts,
    required this.deliveredPieces,
  });

  final int pendingReceipts;
  final int pendingPieces;
  final int deliveredReceipts;
  final int deliveredPieces;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PackageMetricCard(
            label: 'Pendientes',
            value: pendingReceipts.toString(),
            helper: pendingPieces == 1
                ? '1 pieza por entregar'
                : '$pendingPieces piezas por entregar',
            icon: Icons.inventory_2_outlined,
            color: AppColors.packageAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PackageMetricCard(
            label: 'Entregados hoy',
            value: deliveredReceipts.toString(),
            helper: deliveredPieces == 1
                ? '1 pieza entregada'
                : '$deliveredPieces piezas entregadas',
            icon: Icons.task_alt_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _PackageMetricCard extends StatelessWidget {
  const _PackageMetricCard({
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
