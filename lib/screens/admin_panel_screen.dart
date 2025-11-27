import 'package:flutter/material.dart';
import 'package:forex_journal_app/main.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = dbService.getAllUsersForAdmin();
    });
  }

  void _showUserOptions(String uid, String name, String email, String currentRole) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Actions for $name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(email, style: const TextStyle(color: Colors.grey)),
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Change Role'),
              subtitle: Text('Current: ${currentRole.toUpperCase()}'),
              onTap: () {
                Navigator.pop(ctx);
                _showRoleDialog(uid, name);
              },
            ),

            ListTile(
              leading: const Icon(Icons.lock_reset, color: Colors.blue),
              title: const Text('Send Password Reset'),
              subtitle: const Text('Email link to user'),
              onTap: () async {
                Navigator.pop(ctx);
                if (email.contains('@')) {
                  await dbService.adminResetPassword(email);
                  if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reset email sent to $email')));
                } else {
                   if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid email address in DB.')));
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Delete User Data'),
              subtitle: const Text('Wipe accounts, transactions, profile.'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteUser(uid, name);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleDialog(String uid, String name) {
    showDialog(context: context, builder: (ctx) => SimpleDialog(
      title: Text('Select Role for $name'),
      children: [
        SimpleDialogOption(child: const Padding(padding: EdgeInsets.all(8.0), child: Text('STUDENT')), onPressed: () { _updateRole(uid, 'student'); Navigator.pop(ctx); }),
        SimpleDialogOption(child: const Padding(padding: EdgeInsets.all(8.0), child: Text('TEACHER')), onPressed: () { _updateRole(uid, 'teacher'); Navigator.pop(ctx); }),
        SimpleDialogOption(child: const Padding(padding: EdgeInsets.all(8.0), child: Text('ADMIN')), onPressed: () { _updateRole(uid, 'admin'); Navigator.pop(ctx); }),
      ],
    ));
  }

  void _confirmDeleteUser(String uid, String name) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Confirm Delete'),
      content: Text('Are you sure you want to delete all data for $name?\nThis action cannot be undone. The user will need to recreate their profile.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () async {
             Navigator.pop(ctx);
             await dbService.adminDeleteUserData(uid);
             _refreshUsers();
             if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User data deleted.')));
          },
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  void _updateRole(String uid, String role) async {
    await dbService.updateUserRole(uid, role);
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Role updated to: $role')));
    _refreshUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.red.shade800, 
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) return const Center(child: Text("No users found."));

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index];
              final role = user['role'] ?? 'student';
              final email = user['email'] ?? 'No Email';
              final name = user['name'] ?? 'No Name';
              final uid = user['uid'];

              Color roleColor = Colors.grey;
              IconData roleIcon = Icons.person;

              if (role == 'teacher') { roleColor = Colors.orange; roleIcon = Icons.school; } 
              else if (role == 'admin') { roleColor = Colors.red; roleIcon = Icons.security; }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: roleColor.withOpacity(0.2),
                  child: Icon(roleIcon, color: roleColor),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$email\nRole: ${role.toUpperCase()}'),
                trailing: const Icon(Icons.more_vert),
                onTap: () => _showUserOptions(uid, name, email, role),
              );
            },
          );
        },
      ),
    );
  }
}