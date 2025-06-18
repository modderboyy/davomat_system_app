import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUserSearchAppBar extends StatefulWidget {
  final Widget adminContent;
  const AdminUserSearchAppBar({Key? key, required this.adminContent})
      : super(key: key);

  @override
  State<AdminUserSearchAppBar> createState() => _AdminUserSearchAppBarState();
}

class _AdminUserSearchAppBarState extends State<AdminUserSearchAppBar> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allEmployees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  bool _isLoading = true;
  bool _showMenu = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    final companyId = (await Supabase.instance.client
        .from('users')
        .select('company_id')
        .eq('id', user!.id)
        .maybeSingle())?['company_id'];
    final employees = await Supabase.instance.client
        .from('users')
        .select('id, name, email, lavozim')
        .eq('company_id', companyId)
        .neq('is_super_admin', true);
    setState(() {
      _allEmployees = List<Map<String, dynamic>>.from(employees);
      _filteredEmployees = _allEmployees;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEmployees = _allEmployees.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final lavozim = (user['lavozim'] ?? '').toString().toLowerCase();
        return name.contains(query) ||
            email.contains(query) ||
            lavozim.contains(query);
      }).toList();
    });
  }

  Widget _buildAppBar(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding:
              const EdgeInsets.only(top: 32, left: 16, right: 16, bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xff5108c8),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
            gradient: LinearGradient(
              colors: [
                Color(0xFF8811F7), // Asosiy binafsha
                Color(0xFF5A0EBB), // Pastga qarab to‘qroq
                Color(0xFF2F0A6B), // Yana chuqurroq fon
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.15), // Chegara nozik va shaffof
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Color(0xFF8811F7).withOpacity(0.35), // Yengil nur effekti
                blurRadius: 18,
                spreadRadius: 1,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.2), // Pastdan tushadigan chuqur soya
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("Davomat",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          )),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() => _showMenu = !_showMenu),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 26, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        color: Colors.white, size: 22),
                    onPressed: _loadEmployees,
                  ),
                ],
              ),
              if (_showMenu)
                Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading:
                            const Icon(Icons.settings, color: Colors.white),
                        title: const Text("Settings",
                            style: TextStyle(color: Colors.white)),
                        onTap: () => Navigator.pushNamed(context, "/settings"),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.logout, color: Colors.white),
                        title: const Text("Log-out",
                            style: TextStyle(color: Colors.white)),
                        onTap: () async {
                          await Supabase.instance.client.auth.signOut();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Material(
                color: Colors.white.withOpacity(0.9),
                elevation: 0,
                borderRadius: BorderRadius.circular(16),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF5B07E3)),
                    hintText: 'Xodimlarni qidirish (Ism, email, lavozim...)',
                    border: InputBorder.none,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    if (_isLoading) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.only(top: 30),
              child: CircularProgressIndicator()));
    }
    if (_filteredEmployees.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
            child: Text("Xodim topilmadi!", style: TextStyle(fontSize: 16))),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(10),
      itemCount: _filteredEmployees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 5),
      itemBuilder: (context, i) {
        final user = _filteredEmployees[i];
        return Card(
          elevation: 2,
          color: Colors.white.withOpacity(0.95),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF5B07E3).withOpacity(0.15),
              child: const Icon(Icons.person, color: Color(0xFF5B07E3)),
            ),
            title: Text(user['name'] ?? 'No name',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${user['email'] ?? '-'}\n${user['lavozim'] ?? ''}',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context),
        if (_searchController.text.isNotEmpty)
          Expanded(child: _buildEmployeeList())
        else
          Expanded(child: widget.adminContent),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
