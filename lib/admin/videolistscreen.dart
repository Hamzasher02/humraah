import 'dart:io';

import 'package:adminlast/admin/videodetailscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For deletion from storage if needed
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Replace these with your actual imports:

/// ---------------------------------------------------------------------
/// VIDEO LIST SCREEN (Matching the screenshot design, same logic)
/// ---------------------------------------------------------------------
class VideoListScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const VideoListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  // Optional local search input
  String _searchTerm = '';

  @override
  Widget build(BuildContext context) {
    // Firestore stream of videos
    final videosStream =
        FirebaseFirestore.instance
            .collection('categories')
            .doc(widget.categoryId)
            .collection('videos')
            .orderBy('timestamp', descending: true)
            .snapshots();

    return Scaffold(
      backgroundColor: Colors.black,
      // We remove the default AppBar to do a custom top bar
      body: SafeArea(
        child: Column(
          children: [
            // -------------------------------
            // Custom top bar with search + mic
            // -------------------------------
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // "Search bar" container
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              style: const TextStyle(color: Colors.white),
                              onChanged: (val) {
                                setState(() {
                                  _searchTerm = val.trim().toLowerCase();
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'Search here',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          // Red mic icon on the right
                          IconButton(
                            onPressed: () {
                              // If you want voice search logic, do it here
                            },
                            icon: const Icon(Icons.mic, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // "Top Searches" heading

            // -------------------------------
            // The vertical list of videos
            // -------------------------------
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: videosStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // All video docs
                  var videos = snapshot.data!.docs;

                  // If you want local search filtering:
                  if (_searchTerm.isNotEmpty) {
                    videos =
                        videos.where((doc) {
                          final data = doc.data() as Map<String, dynamic>?;
                          if (data == null) return false;
                          final name =
                              (data['name'] ?? '').toString().toLowerCase();
                          return name.contains(_searchTerm);
                        }).toList();
                  }

                  if (videos.isEmpty) {
                    return const Center(
                      child: Text(
                        'No videos found.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final videoDoc = videos[index];
                      final docId = videoDoc.id;
                      final data = videoDoc.data() as Map<String, dynamic>?;

                      if (data == null) {
                        return const ListTile(
                          title: Text(
                            'Video data is null',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      final name = data['name'] as String? ?? 'No Name';
                      final description = data['description'] as String? ?? '';
                      final thumbnail = data['thumbnail'] as String?;
                      final videoUrl = data['url'] as String?;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ListTile(
                          // Thumbnail on the left
                          leading:
                              thumbnail != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      thumbnail,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.white,
                                  ),

                          // Name & description in the center
                          title: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),

                          // Tapping => go to VideoDetailScreen
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (ctx) => VideoDetailScreen(
                                      categoryId: widget.categoryId,
                                      videoId: docId,
                                    ),
                              ),
                            );
                          },

                          // trailing popup menu for edit/delete
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditDialog(
                                  context,
                                  docId,
                                  name,
                                  description,
                                );
                              } else if (value == 'delete') {
                                _showDeleteDialog(
                                  context,
                                  docId,
                                  name,
                                  thumbnail,
                                  videoUrl,
                                );
                              }
                            },
                            itemBuilder:
                                (ctx) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                            icon: const Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Floating action button to add a new video
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => AddVideoScreen(categoryId: widget.categoryId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Show a dialog to edit a video's name/description
  // -------------------------------------------------------------------
  void _showEditDialog(
    BuildContext context,
    String docId,
    String oldName,
    String oldDesc,
  ) {
    final nameCtrl = TextEditingController(text: oldName);
    final descCtrl = TextEditingController(text: oldDesc);

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Edit Video'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Video Name'),
                  ),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Video Description',
                    ),
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
                  final newName = nameCtrl.text.trim();
                  final newDesc = descCtrl.text.trim();
                  if (newName.isEmpty) {
                    _showSnackBar(context, 'Name cannot be empty');
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('categories')
                        .doc(widget.categoryId)
                        .collection('videos')
                        .doc(docId)
                        .update({'name': newName, 'description': newDesc});
                    _showSnackBar(context, 'Video updated successfully!');
                    Navigator.pop(ctx);
                  } catch (e) {
                    _showSnackBar(context, 'Failed to update video: $e');
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  // -------------------------------------------------------------------
  // Show a confirmation dialog to delete a video
  // -------------------------------------------------------------------
  void _showDeleteDialog(
    BuildContext context,
    String docId,
    String videoName,
    String? thumbnailUrl,
    String? videoUrl,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Video'),
            content: Text('Are you sure you want to delete "$videoName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);

                  try {
                    // Optional: remove files from Storage
                    /*
                if (thumbnailUrl != null) {
                  await FirebaseStorage.instance.refFromURL(thumbnailUrl).delete();
                }
                if (videoUrl != null) {
                  await FirebaseStorage.instance.refFromURL(videoUrl).delete();
                }
                */

                    await FirebaseFirestore.instance
                        .collection('categories')
                        .doc(widget.categoryId)
                        .collection('videos')
                        .doc(docId)
                        .delete();

                    _showSnackBar(context, 'Video deleted successfully!');
                  } catch (e) {
                    _showSnackBar(context, 'Failed to delete video: $e');
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  // -------------------------------------------------------------------
  // Helper to show a SnackBar
  // -------------------------------------------------------------------
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// ---------------------------------------------------------------------
/// ADD VIDEO SCREEN (with progress indicator)
/// ---------------------------------------------------------------------

class AddVideoScreen extends StatefulWidget {
  final String categoryId;

  const AddVideoScreen({super.key, required this.categoryId});

  @override
  _AddVideoScreenState createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _thumbnail;
  File? _video;

  // Upload progress from 0.0 to 1.0
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  /// Request media permissions for Android 14 (Android 13+).
  /// On Android, request separate permissions for images and videos.
  Future<bool> _requestMediaPermissions() async {
    if (Platform.isAndroid) {
      final photosStatus = await Permission.photos.request();
      final videosStatus = await Permission.videos.request();
      return photosStatus.isGranted && videosStatus.isGranted;
    } else {
      // For iOS, you may only need the photos permission.
      final status = await Permission.photos.request();
      return status.isGranted;
    }
  }

  Future<void> _pickImage() async {
    final granted = await _requestMediaPermissions();
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media permissions not granted')),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        debugPrint('No image selected');
        return;
      }
      setState(() {
        _thumbnail = File(pickedFile.path);
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickVideo() async {
    final granted = await _requestMediaPermissions();
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media permissions not granted')),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile == null) {
        debugPrint('No video selected');
        return;
      }
      setState(() {
        _video = File(pickedFile.path);
      });
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  Future<void> _uploadVideo() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty ||
        description.isEmpty ||
        _thumbnail == null ||
        _video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide name, description, thumbnail, and video.',
          ),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final videoId = const Uuid().v4();
      final thumbPath = 'thumbnails/$videoId.png';
      final videoPath = 'videos/$videoId.mp4';

      // 1. Upload thumbnail
      final thumbRef = FirebaseStorage.instance.ref(thumbPath);
      await thumbRef.putFile(_thumbnail!);
      final thumbUrl = await thumbRef.getDownloadURL();

      // 2. Upload video with progress
      final videoRef = FirebaseStorage.instance.ref(videoPath);
      final uploadTask = videoRef.putFile(_video!);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress = progress;
        });
      });

      await uploadTask.whenComplete(() => null);
      final videoUrl = await videoRef.getDownloadURL();

      // 3. Store Firestore document
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryId)
          .collection('videos')
          .doc(videoId)
          .set({
            'name': name,
            'description': description,
            'thumbnail': thumbUrl,
            'url': videoUrl,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video uploaded successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error uploading video: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading video: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int percentage = (_uploadProgress * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Video')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Video name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Video Name'),
              ),
              // Video description
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Video Description',
                ),
              ),
              const SizedBox(height: 20),

              // Pick thumbnail
              GestureDetector(
                onTap: _pickImage,
                child:
                    _thumbnail == null
                        ? Column(
                          children: const [
                            Icon(Icons.add_a_photo, size: 50),
                            SizedBox(height: 8),
                            Text('Pick Thumbnail'),
                          ],
                        )
                        : Image.file(_thumbnail!, height: 100),
              ),
              const SizedBox(height: 20),

              // Pick video
              GestureDetector(
                onTap: _pickVideo,
                child:
                    _video == null
                        ? Column(
                          children: const [
                            Icon(Icons.video_library, size: 50),
                            SizedBox(height: 8),
                            Text('Pick Video'),
                          ],
                        )
                        : const Text(
                          'Video Selected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
              const SizedBox(height: 20),

              // Show progress if uploading
              if (_isUploading) ...[
                Text('Uploading: $percentage%'),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 20),
              ],

              ElevatedButton(
                onPressed: _isUploading ? null : _uploadVideo,
                child: Text(_isUploading ? 'Uploading...' : 'Upload Video'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
