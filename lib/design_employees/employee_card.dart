import 'package:flutter/material.dart';

class EmployeeCard extends StatelessWidget {
  final String name;
  final String role;
  final VoidCallback onEdit;

  const EmployeeCard({
    super.key,
    required this.name,
    required this.role,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.indigo.shade100],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.indigo.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade200,
          child: Text(
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(role, style: TextStyle(color: Colors.indigo[700])),
        trailing: IconButton(
          icon: Icon(Icons.edit, color: Colors.indigo),
          onPressed: onEdit,
          tooltip: "Tahrirlash",
        ),
      ),
    );
  }
}
