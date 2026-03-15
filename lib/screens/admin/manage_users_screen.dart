import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<User> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService().get('users/read.php');
      if (res['success'] == true) {
        setState(() {
          _users = (res['data'] as List).map((e) => User.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = res['message']; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registered Users')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _users.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final u = _users[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: u.isAdmin
                                ? Colors.indigo.withValues(alpha: 0.15)
                                : Colors.teal.withValues(alpha: 0.15),
                            child: Icon(
                              u.isAdmin ? Icons.admin_panel_settings : Icons.person,
                              color: u.isAdmin ? Colors.indigo : Colors.teal,
                            ),
                          ),
                          title: Text(u.name,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(u.email),
                          trailing: Chip(
                            label: Text(u.role.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.white)),
                            backgroundColor:
                                u.isAdmin ? Colors.indigo : Colors.teal,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      },
                    ),
    );
  }
}
