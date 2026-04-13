import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class HomeSummaryStrip extends StatelessWidget {
  const HomeSummaryStrip({
    super.key,
    required this.insidePeopleCount,
    required this.activeVisitCount,
    required this.latestEntryLabel,
  });

  final int insidePeopleCount;
  final int activeVisitCount;
  final String latestEntryLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Personas dentro',
            value: insidePeopleCount.toString(),
            helper: activeVisitCount == 1
                ? '1 visita activa'
                : '$activeVisitCount visitas activas',
            icon: Icons.groups_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            label: 'Ultimo ingreso',
            value: latestEntryLabel,
            helper: 'Hora de entrada mas reciente',
            icon: Icons.schedule_rounded,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.helper,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? helper;

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
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
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
                letterSpacing: -0.4,
              ),
            ),
            if ((helper ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                helper!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.textSoft
                      : AppColors.midnight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
