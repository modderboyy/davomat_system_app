import 'package:flutter/material.dart';

class EditEmployeeSheet extends StatefulWidget {
  final String initialName;
  final String initialRole;
  final Function(String, String) onSave;

  const EditEmployeeSheet({
    super.key,
    required this.initialName,
    required this.initialRole,
    required this.onSave,
  });

  @override
  State<EditEmployeeSheet> createState() => _EditEmployeeSheetState();
}

class _EditEmployeeSheetState extends State<EditEmployeeSheet>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _roleController = TextEditingController(text: widget.initialRole);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
      child: Padding(
        padding:
            MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Xodimni tahrirlash",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Ism, familiya"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _roleController,
              decoration: InputDecoration(labelText: "Lavozim"),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text("Saqlash"),
              onPressed: () {
                widget.onSave(_nameController.text, _roleController.text);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(45)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
