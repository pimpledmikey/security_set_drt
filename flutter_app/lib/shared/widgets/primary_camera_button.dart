import 'package:flutter/material.dart';

class PrimaryCameraButton extends StatelessWidget {
  const PrimaryCameraButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.document_scanner_rounded,
    this.label = 'Escanear acceso',
    this.backgroundColor,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 64,
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        icon: Icon(icon, size: 26),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
