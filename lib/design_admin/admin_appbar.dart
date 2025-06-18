import 'package:flutter/material.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String currentLanguage;
  final Function(String) onLanguageChanged;

  const AdminAppBar({
    Key? key,
    required this.title,
    required this.currentLanguage,
    required this.onLanguageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      elevation: 1,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.translate_outlined),
          tooltip: 'Tilni tanlash',
          onSelected: onLanguageChanged,
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(value: 'en', child: Text('English')),
            const PopupMenuItem<String>(value: 'uz', child: Text("O'zbek")),
            const PopupMenuItem<String>(value: 'ru', child: Text('Русский')),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
