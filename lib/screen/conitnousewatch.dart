import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ContinueWatchingScreen extends StatelessWidget {
  const ContinueWatchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in first.'));
    }

    final continueWatchingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('continueWatching')
        .orderBy('updatedAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Continue Watching')),
      body: StreamBuilder<QuerySnapshot>(
        stream: continueWatchingRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No videos in Continue Watching.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Untitled';
              final position = data['position'] ?? 0;
              final duration = data['duration'] ?? 1;
              final progress = (position / duration) * 100;

              return ListTile(
                title: Text(title),
                subtitle: Text(
                  'Watched ${(progress).toStringAsFixed(0)}% of this video',
                ),
                onTap: () {
                  // Navigate to the detail page with the categoryId, videoId
                  // to continue from last saved position
                },
              );
            },
          );
        },
      ),
    );
  }
}
