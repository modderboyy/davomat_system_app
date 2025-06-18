import 'package:flutter/material.dart';

class AdminInfoPanel extends StatelessWidget {
  final bool isLoading;
  final String? companyName;
  final String? userEmail;
  final int employeeCount;
  final int freeEmployeeLimit;
  final double costPerExtraEmployee;
  final DateTime? lastUpdated;
  final String Function(String, [Map<String, dynamic>?]) translate;

  const AdminInfoPanel({
    Key? key,
    required this.isLoading,
    required this.companyName,
    required this.userEmail,
    required this.employeeCount,
    required this.freeEmployeeLimit,
    required this.costPerExtraEmployee,
    required this.lastUpdated,
    required this.translate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading && companyName == null && userEmail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(18.0),
      children: [
        Text(translate('general_info'),
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.primaryColor)),
        const Divider(thickness: 1, height: 20),
        _infoTile(
            icon: Icons.business_outlined,
            title: translate('company_name'),
            subtitle: companyName ?? translate('loading'),
            context: context),
        _infoTile(
            icon: Icons.alternate_email_outlined,
            title: translate('user_email'),
            subtitle: userEmail ?? translate('loading'),
            context: context),
        const SizedBox(height: 24),
        Text(translate('employees'),
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.primaryColor)),
        const Divider(thickness: 1, height: 20),
        _infoTile(
            icon: Icons.people_outline,
            title: translate('total_employees', {'count': ''})
                .replaceAll(': {count}', ''),
            subtitle: employeeCount.toString(),
            context: context),
        _infoTile(
            icon: Icons.money_off_csred_outlined,
            title: translate('free_employees', {'count': ''})
                .replaceAll(': {count}', ''),
            subtitle: freeEmployeeLimit.toString(),
            context: context),
        _infoTile(
            icon: Icons.price_change_outlined,
            title: translate('cost_per_additional_employee', {'cost': ''})
                .replaceAll(': \${cost}/month', ''),
            subtitle: '\$${costPerExtraEmployee.toStringAsFixed(2)} / oy',
            context: context),
      ],
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.primaryColor.withOpacity(0.8)),
      title: Text(title,
          style: theme.textTheme.labelLarge
              ?.copyWith(color: Colors.grey.shade600)),
      subtitle: Text(subtitle,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w500)),
      contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
    );
  }
}
