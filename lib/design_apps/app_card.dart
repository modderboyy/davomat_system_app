import 'package:flutter/material.dart';
import 'app_logo.dart';
import 'app_type_chip.dart';

class AppCard extends StatelessWidget {
  final Map<String, dynamic> app;
  final VoidCallback onTap;
  final String publicLabel;
  final String privateLabel;

  const AppCard({
    Key? key,
    required this.app,
    required this.onTap,
    required this.publicLabel,
    required this.privateLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logoUrl = app['logo_url'] as String?;
    final appName = app['name'] as String? ?? 'App';
    final appType = app['type'] as String? ?? 'public';
    final appUsername = app['username'] as String? ?? '';
    final companyData = app['companies!apps_created_by_company_id_fkey'];
    String creator = publicLabel;
    if (companyData != null &&
        companyData is Map &&
        companyData['company_name'] != null) {
      creator = companyData['company_name'] as String;
    } else if (appType == 'private') {
      creator = privateLabel;
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              AppLogo(logoUrl: logoUrl, size: 54),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(appName,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold))),
                        AppTypeChip(
                            type: appType,
                            label: appType == 'public'
                                ? publicLabel
                                : privateLabel),
                      ],
                    ),
                    if (appUsername.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3.0),
                        child: Text(appUsername,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w500)),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(creator,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
