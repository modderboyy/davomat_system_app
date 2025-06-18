import 'package:flutter/material.dart';
import 'employee_card.dart';
import 'edit_employee_sheet.dart';

class EmployeesPage extends StatelessWidget {
  final List<Map<String, dynamic>> employees;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Function(String, String, String) onEdit;

  const EmployeesPage({
    Key? key,
    required this.employees,
    required this.isLoading,
    required this.onRefresh,
    required this.onEdit,
  }) : super(key: key);

  void _showEdit(BuildContext context, Map<String, dynamic> emp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditEmployeeSheet(
        initialName: emp['name'] ?? '',
        initialRole: emp['lavozim'] ?? '',
        onSave: (String newName, String newRole) =>
            onEdit(emp['id'], newName, newRole),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 18, bottom: 80),
                itemCount: employees.length,
                itemBuilder: (context, i) {
                  final emp = employees[i];
                  return EmployeeCard(
                    name: emp['name'] ?? '-',
                    role: emp['lavozim'] ?? '-',
                    onEdit: () => _showEdit(context, emp),
                  );
                },
              ),
            ),
    );
  }
}
