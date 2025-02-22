import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  /// We'll assume your Firestore has a top-level collection named "users".
  /// Each user doc might have fields like: "email", "role", "createdAt", etc.

  @override
  Widget build(BuildContext context) {
    // Stream of all docs in "users"
    final usersStream =
        FirebaseFirestore.instance
            .collection('users')
            .orderBy(
              'createdAt',
              descending: true,
            ) // or order by "email" or "name"
            .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('User Screen')),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userDocs = snapshot.data!.docs;
          if (userDocs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          // Display the users in a ListView
          return ListView.builder(
            itemCount: userDocs.length,
            itemBuilder: (context, index) {
              final doc = userDocs[index];
              final docId = doc.id;
              final data = doc.data() as Map<String, dynamic>?;

              if (data == null) {
                return const ListTile(title: Text('User data is null'));
              }

              // Example fields from your screenshot: "email", "role", "createdAt"
              final email = data['email'] as String? ?? 'No Email';
              final role = data['role'] as String? ?? 'No Role';
              final createdAt =
                  data['createdAt']?.toDate()?.toString() ??
                  data['createdAt']?.toString() ??
                  'No date';

              return ListTile(
                title: Text(email),
                subtitle: Text('Role: $role\nCreated: $createdAt'),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'change') {
                      // Edit user fields
                      _showChangeDialog(context, docId, email, role);
                    } else if (value == 'delete') {
                      // Delete user doc
                      _showDeleteDialog(context, docId, email);
                    }
                  },
                  itemBuilder:
                      (ctx) => [
                        const PopupMenuItem(
                          value: 'change',
                          child: Text('Change'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------
  // Show a dialog to change (edit) the user's fields
  // -------------------------------------------------------------------
  void _showChangeDialog(
    BuildContext context,
    String docId,
    String oldEmail,
    String oldRole,
  ) {
    final emailCtrl = TextEditingController(text: oldEmail);
    final roleCtrl = TextEditingController(text: oldRole);

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Change User Fields'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: roleCtrl,
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final newEmail = emailCtrl.text.trim();
                  final newRole = roleCtrl.text.trim();
                  if (newEmail.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email cannot be empty')),
                    );
                    return;
                  }
                  if (newRole.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Role cannot be empty')),
                    );
                    return;
                  }

                  try {
                    // Update Firestore doc
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(docId)
                        .update({
                          'email': newEmail,
                          'role': newRole,
                          // If you want to track "updatedAt", add it here
                        });

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User updated successfully!'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update user: $e')),
                    );
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  // -------------------------------------------------------------------
  // Show a confirmation dialog to delete user doc
  // -------------------------------------------------------------------
  void _showDeleteDialog(BuildContext context, String docId, String userEmail) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Account'),
            content: Text('Are you sure you want to delete "$userEmail"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    // Delete the user doc from Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(docId)
                        .delete();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User deleted successfully!'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete user: $e')),
                    );
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
