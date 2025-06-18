import 'package:flutter/material.dart';

class AdminHomePanel extends StatelessWidget {
  final bool isLoading;
  final String? companyName;
  final String? userEmail;
  final double balance;
  final int employeeCount;
  final int freeEmployeeLimit;
  final double costPerExtraEmployee;
  final DateTime? lastUpdated;
  final List<Map<String, dynamic>> transactions;
  final String Function(String, [Map<String, dynamic>?]) translate;
  final VoidCallback onDeposit;

  const AdminHomePanel({
    Key? key,
    required this.isLoading,
    required this.companyName,
    required this.userEmail,
    required this.balance,
    required this.employeeCount,
    required this.freeEmployeeLimit,
    required this.costPerExtraEmployee,
    required this.lastUpdated,
    required this.transactions,
    required this.translate,
    required this.onDeposit,
  }) : super(key: key);

  double _calculateMonthlyCost() {
    if (employeeCount <= freeEmployeeLimit) return 0.0;
    return (employeeCount - freeEmployeeLimit) * costPerExtraEmployee;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double monthlyCost = _calculateMonthlyCost();
    final int paidEmployees = employeeCount > freeEmployeeLimit
        ? employeeCount - freeEmployeeLimit
        : 0;

    if (isLoading && companyName == null && userEmail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async => onDeposit(),
      color: theme.primaryColor,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(companyName ?? translate('loading'),
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(translate('balance'),
                      style: theme.textTheme.titleMedium),
                  Text('\$${balance.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: balance >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700)),
                  const Divider(height: 30, thickness: 1.3),
                  Text(translate('employees'),
                      style: theme.textTheme.titleMedium),
                  Text(translate('total_employees', {'count': employeeCount}),
                      style: theme.textTheme.titleMedium),
                  Text(
                      translate('free_employees', {'count': freeEmployeeLimit}),
                      style: theme.textTheme.bodyMedium),
                  Text(translate('paid_employees', {'count': paidEmployees}),
                      style: theme.textTheme.bodyMedium),
                  Text(
                      translate('cost_per_additional_employee',
                          {'cost': costPerExtraEmployee.toStringAsFixed(2)}),
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  Text(
                      translate('monthly_cost',
                          {'cost': monthlyCost.toStringAsFixed(2)}),
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: monthlyCost > balance
                              ? Colors.red.shade700
                              : theme.primaryColor)),
                  const SizedBox(height: 10),
                  Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                          translate('last_updated_data', {
                            'datetime': lastUpdated != null
                                ? lastUpdated.toString().substring(0, 16)
                                : '-'
                          }),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
            label: Text(translate('deposit_funds'),
                style: const TextStyle(fontSize: 16)),
            onPressed: onDeposit,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 28),
          Text(translate('transactions_history'),
              style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.primaryColor, fontWeight: FontWeight.bold)),
          const Divider(thickness: 1.5, height: 20),
          transactions.isEmpty
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(translate('no_transactions_found'),
                          style: TextStyle(color: Colors.grey[600]))))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final String type =
                        transaction['transaction_type'] as String? ?? 'N/A';
                    final double amount =
                        (transaction['amount'] as num?)?.toDouble() ?? 0.0;
                    final String date =
                        transaction['created_at']?.toString() ?? '-';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: Icon(
                            type == 'deposit'
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color:
                                type == 'deposit' ? Colors.green : Colors.red),
                        title: Text(type),
                        subtitle: Text(date),
                        trailing: Text(
                          '\$${amount.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                              color:
                                  type == 'deposit' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    );
                  }),
        ],
      ),
    );
  }
}
