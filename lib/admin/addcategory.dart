import 'package:adminlast/admin/videolistscreen.dart';
import 'package:adminlast/screen/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------
///  CATEGORIES SCREEN (with scrollable list, add, update, delete)
/// ---------------------------------------------------------------------
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _categoryController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a new category document
  Future<void> _addCategory() async {
    final catName = _categoryController.text.trim();
    if (catName.isEmpty) {
      _showSnackBar('Please enter a category name');
      return;
    }

    try {
      await _firestore.collection('categories').add({
        'name': catName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context); // close dialog
      _showSnackBar('Category added successfully!');
      _categoryController.clear();
    } catch (e) {
      _showSnackBar('Failed to add category: $e');
    }
  }

  /// Show a dialog to input category name
  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        _categoryController.clear();
        return AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            controller: _categoryController,
            decoration: const InputDecoration(hintText: 'Category name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(onPressed: _addCategory, child: const Text('Add')),
          ],
        );
      },
    );
  }

  /// Delete a category by document ID
  Future<void> _deleteCategory(String docId) async {
    try {
      await _firestore.collection('categories').doc(docId).delete();
      _showSnackBar('Category deleted successfully!');
    } catch (e) {
      _showSnackBar('Failed to delete category: $e');
    }
  }

  /// Update a category's name (show dialog, then Firestore update)
  Future<void> _updateCategory(String docId, String oldName) async {
    final TextEditingController updateController = TextEditingController(
      text: oldName,
    );

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Update Category'),
            content: TextField(
              controller: updateController,
              decoration: const InputDecoration(hintText: 'New category name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final newName = updateController.text.trim();
                  if (newName.isEmpty) {
                    _showSnackBar('Name cannot be empty');
                    return;
                  }
                  try {
                    await _firestore.collection('categories').doc(docId).update(
                      {'name': newName},
                    );
                    Navigator.pop(ctx);
                    _showSnackBar('Category updated successfully!');
                  } catch (e) {
                    _showSnackBar('Failed to update category: $e');
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  /// Helper to show SnackBar messages
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final categoriesStream =
        _firestore
            .collection('categories')
            .orderBy('timestamp', descending: true)
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),

        leading: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
          },
          child: Icon(Icons.person, color: Colors.red),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: categoriesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!.docs;
          if (categories.isEmpty) {
            return const Center(child: Text('No categories yet.'));
          }

          // ListView is already scrollable by default
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final categoryDoc = categories[index];
              final categoryData = categoryDoc.data() as Map<String, dynamic>;
              final docId = categoryDoc.id;
              final name = categoryData['name'] as String? ?? 'No name';

              return ListTile(
                title: Text(name),
                onTap: () {
                  // Navigate to VideoListScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (ctx) => VideoListScreen(
                            categoryId: docId,
                            categoryName: name,
                          ),
                    ),
                  );
                },
                // Popup menu to Update/Delete
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _updateCategory(docId, name);
                    } else if (value == 'delete') {
                      // Confirm delete
                      showDialog(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: Text('Delete "$name" category?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _deleteCategory(docId);
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                      );
                    }
                  },
                  itemBuilder:
                      (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
