import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../models/active_visit_item.dart';

class ActiveVisitCard extends StatelessWidget {
  const ActiveVisitCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onCheckout,
  });

  final ActiveVisitItem item;
  final VoidCallback onTap;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VisitorAvatar(fullName: item.fullName),
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
                                item.fullName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
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
                        const SizedBox(width: 12),
                        _EntryTimeChip(
                          timeLabel:
                              DateTimeFormatter.shortTime(item.enteredAt),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.badge_outlined,
                          label: item.identifierLabel,
                        ),
                        _InfoChip(
                          icon: item.hasAppointment
                              ? Icons.event_available_outlined
                              : Icons.event_busy_outlined,
                          label: item.hasAppointment ? 'Cita: Si' : 'Cita: No',
                        ),
                        _InfoChip(
                          icon: Icons.groups_2_outlined,
                          label: item.groupSize == 1
                              ? '1 persona'
                              : '${item.groupSize} personas',
                        ),
                        _InfoChip(
                          icon: Icons.business_center_outlined,
                          label: item.purpose,
                        ),
                      ],
                    ),
                    if (item.observations.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.observations,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.brightness == Brightness.dark
                                    ? AppColors.textSoft
                                    : AppColors.midnight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onCheckout,
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Registrar salida'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.warning.withValues(
                                alpha: theme.brightness == Brightness.dark
                                    ? 0.12
                                    : 0.08,
                              ),
                              foregroundColor:
                                  theme.brightness == Brightness.dark
                                      ? const Color(0xFFFFD8A8)
                                      : const Color(0xFFA35A00),
                              side: BorderSide(
                                color: AppColors.warning.withValues(
                                  alpha: theme.brightness == Brightness.dark
                                      ? 0.18
                                      : 0.14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.primary,
                        ),
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

class _EntryTimeChip extends StatelessWidget {
  const _EntryTimeChip({required this.timeLabel});

  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark
        ? AppColors.accentSoft
        : AppColors.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.12 : 0.08,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.18 : 0.12,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Entrada',
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            timeLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitorAvatar extends StatelessWidget {
  const _VisitorAvatar({required this.fullName});

  final String fullName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '--' : initials,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.primary,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
