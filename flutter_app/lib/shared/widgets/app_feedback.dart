import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

enum AppFeedbackTone {
  success,
  error,
  warning,
  info,
  package,
  collection,
}

void showAppFeedback(
  BuildContext context,
  String message, {
  AppFeedbackTone tone = AppFeedbackTone.info,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final style = _AppFeedbackStyle.fromTone(tone);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: style.backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x260B1426),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: style.borderColor,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: style.badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  style.icon,
                  size: 18,
                  color: style.iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: style.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

class _AppFeedbackStyle {
  const _AppFeedbackStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.badgeColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color badgeColor;
  final Color iconColor;
  final Color textColor;
  final IconData icon;

  factory _AppFeedbackStyle.fromTone(AppFeedbackTone tone) {
    switch (tone) {
      case AppFeedbackTone.success:
        return const _AppFeedbackStyle(
          backgroundColor: AppColors.success,
          borderColor: Color(0xFF16A34A),
          badgeColor: Color(0x33FFFFFF),
          iconColor: Colors.white,
          textColor: Colors.white,
          icon: Icons.check_circle_rounded,
        );
      case AppFeedbackTone.error:
        return const _AppFeedbackStyle(
          backgroundColor: AppColors.danger,
          borderColor: Color(0xFFDC2626),
          badgeColor: Color(0x33FFFFFF),
          iconColor: Colors.white,
          textColor: Colors.white,
          icon: Icons.error_rounded,
        );
      case AppFeedbackTone.warning:
        return const _AppFeedbackStyle(
          backgroundColor: AppColors.warning,
          borderColor: Color(0xFFD97706),
          badgeColor: Color(0x26FFFFFF),
          iconColor: AppColors.midnight,
          textColor: AppColors.midnight,
          icon: Icons.warning_amber_rounded,
        );
      case AppFeedbackTone.package:
        return const _AppFeedbackStyle(
          backgroundColor: AppColors.packageAccent,
          borderColor: Color(0xFF0F766E),
          badgeColor: Color(0x33FFFFFF),
          iconColor: Colors.white,
          textColor: Colors.white,
          icon: Icons.inventory_2_rounded,
        );
      case AppFeedbackTone.collection:
        return const _AppFeedbackStyle(
          backgroundColor: AppColors.collectionAccent,
          borderColor: Color(0xFF92400E),
          badgeColor: Color(0x33FFFFFF),
          iconColor: Colors.white,
          textColor: Colors.white,
          icon: Icons.local_shipping_rounded,
        );
      case AppFeedbackTone.info:
        return const _AppFeedbackStyle(
          backgroundColor: AppColors.accent,
          borderColor: Color(0xFF1D4ED8),
          badgeColor: Color(0x33FFFFFF),
          iconColor: Colors.white,
          textColor: Colors.white,
          icon: Icons.info_rounded,
        );
    }
  }
}
