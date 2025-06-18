import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUserSearchAppBar extends StatefulWidget {
  final Widget adminContent;
  final String currentLanguage;
  final String Function(String) translate;
  
  const AdminUserSearchAppBar({
    Key? key, 
    required this.adminContent,
    required this.currentLanguage,
    required this.translate,
  }) : super(key: key);

  @override
  State<AdminUserSearchAppBar> createState() => _AdminUserSearchAppBarState();
}

class _AdminUserSearchAppBarState extends State<AdminUserSearchAppBar> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allEmployees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  bool _isLoading = true;
  bool _showSearchResults = false;

  // Modern colors
  static const Color primaryColor = Color(0xFF6e38c9);
  static const Color secondaryColor = Color(0xFF9c6bff);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final userResponse = await Supabase.instance.client
          .from('users')
          .select('company_id')
          .eq('id', user.id)
          .maybeSingle();

      final companyId = userResponse?['company_id'];
      if (companyId == null) return;

      final employees = await Supabase.instance.client
          .from('users')
          .select('id, full_name, email, position, profile_image')
          .eq('company_id', companyId)
          .neq('is_super_admin', true);

      setState(() {
        _allEmployees = List<Map<String, dynamic>>.from(employees);
        _filteredEmployees = _allEmployees;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading employees: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _showSearchResults = query.isNotEmpty;
      if (query.isNotEmpty) {
        _filteredEmployees = _allEmployees.where((user) {
          final name = (user['full_name'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          final position = (user['position'] ?? '').toString().toLowerCase();
          return name.contains(query) ||
              email.contains(query) ||
              position.contains(query);
        }).toList();
      } else {
        _filteredEmployees = _allEmployees;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildModernSearchBar(),
        Expanded(
          child: _showSearchResults 
              ? _buildSearchResults()
              : widget.adminContent,
        ),
      ],
    );
  }

  Widget _buildModernSearchBar() {
    return Container(
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 16, color: textPrimary),
        decoration: InputDecoration(
          hintText: widget.translate('search_employees'),
          hintStyle: TextStyle(color: textSecondary),
          prefixIcon: Icon(CupertinoIcons.search, color: primaryColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(CupertinoIcons.clear, color: textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _showSearchResults = false);
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    }

    if (_filteredEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_3,
              size: 60,
              color: textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Xodim topilmadi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Boshqa kalit so\'z bilan qidiring',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = _filteredEmployees[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: employee['profile_image'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        employee['profile_image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(CupertinoIcons.person_fill,
                                color: Colors.white, size: 24),
                      ),
                    )
                  : Icon(CupertinoIcons.person_fill,
                      color: Colors.white, size: 24),
            ),
            title: Text(
              employee['full_name'] ?? 'Unknown',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (employee['position'] != null) ...[
                  SizedBox(height: 4),
                  Text(
                    employee['position'],
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (employee['email'] != null) ...[
                  SizedBox(height: 2),
                  Text(
                    employee['email'],
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
            trailing: Icon(
              CupertinoIcons.chevron_right,
              color: textSecondary,
              size: 16,
            ),
            onTap: () {
              // Handle employee tap - could show details or navigate
              _showEmployeeDetails(employee);
            },
          ),
        );
      },
    );
  }

  void _showEmployeeDetails(Map<String, dynamic> employee) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            // Employee info
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: employee['profile_image'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        employee['profile_image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(CupertinoIcons.person_fill,
                                color: Colors.white, size: 40),
                      ),
                    )
                  : Icon(CupertinoIcons.person_fill,
                      color: Colors.white, size: 40),
            ),
            SizedBox(height: 16),
            Text(
              employee['full_name'] ?? 'Unknown',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            if (employee['position'] != null) ...[
              SizedBox(height: 8),
              Text(
                employee['position'],
                style: TextStyle(
                  fontSize: 16,
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (employee['email'] != null) ...[
              SizedBox(height: 8),
              Text(
                employee['email'],
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ],
            SizedBox(height: 32),
            // Action buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Show attendance history for this employee
                      },
                      icon: Icon(CupertinoIcons.calendar),
                      label: Text('Davomat tarixi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Edit employee
                      },
                      icon: Icon(CupertinoIcons.pencil),
                      label: Text('Tahrirlash'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}