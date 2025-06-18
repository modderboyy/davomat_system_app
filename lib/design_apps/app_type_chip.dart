import 'package:flutter/material.dart';

class AppTypeChip extends StatelessWidget {
  final String type; // 'public' yoki 'private'
  final String label;

  const AppTypeChip({Key? key, required this.type, required this.label})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bg = type == 'private'
        ? Colors.indigo.withOpacity(0.15)
        : Colors.green.withOpacity(0.12);
    Color fg = type == 'private' ? Colors.indigo : Colors.green[800]!;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(label,
          style:
              TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
