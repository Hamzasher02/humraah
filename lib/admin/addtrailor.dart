import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

/// IMPORTANT:
/// For Android (API 33 and above), add the following in your AndroidManifest.xml:
///   <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
///   <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
/// For Android below API 33, the legacy STORAGE permission is used automatically by permission_handler.
/// For iOS, add these keys in Info.plist:
///   NSPhotoLibraryUsageDescription, NSCameraUsageDescription, NSMicrophoneUsageDescription

/// Screen to add a new trailer (with thumbnail and video)
class AddTrailerScreen extends StatefulWidget {
  const AddTrailerScreen({super.key});

  @override
  _AddTrailerScreenState createState() => _AddTrailerScreenState();
}

class _AddTrailerScreenState extends State<AddTrailerScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _thumbnail;
  File? _video;

  bool _isUploading = false;
  double _uploadProgress = 0.0;

  /// Request media permissions.
  /// For Android 13/14: request Permission.photos for images and Permission.videos for videos.
  Future<bool> _requestMediaPermissions({required bool forImage}) async {
    if (Platform.isAndroid) {
      if (forImage) {
        final status = await Permission.photos.request();
        return status.isGranted;
      } else {
        final status = await Permission.videos.request();
        return status.isGranted;
      }
    } else {
      // On iOS, request photos permission (covers both images and videos).
      final status = await Permission.photos.request();
      return status.isGranted;
    }
  }

  /// Pick a thumbnail image from gallery.
  Future<void> _pickImage() async {
    final granted = await _requestMediaPermissions(forImage: true);
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

  /// Pick a trailer video from gallery.
  Future<void> _pickVideo() async {
    final granted = await _requestMediaPermissions(forImage: false);
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

  /// Upload the trailer with progress tracking.
  Future<void> _uploadTrailer() async {
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

      final trailerId = const Uuid().v4();
      final thumbPath = 'trailers_thumbnails/$trailerId.png';
      final videoPath = 'trailers_videos/$trailerId.mp4';

      // 1. Upload thumbnail.
      final thumbRef = FirebaseStorage.instance.ref(thumbPath);
      await thumbRef.putFile(_thumbnail!);
      final thumbUrl = await thumbRef.getDownloadURL();

      // 2. Upload video with progress tracking.
      final videoRef = FirebaseStorage.instance.ref(videoPath);
      final uploadTask = videoRef.putFile(_video!);

      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress = progress;
        });
      });

      await uploadTask.whenComplete(() => null);
      final videoUrl = await videoRef.getDownloadURL();

      // 3. Store trailer details in Firestore.
      await FirebaseFirestore.instance
          .collection('trailers')
          .doc(trailerId)
          .set({
            'name': name,
            'description': description,
            'thumbnail': thumbUrl,
            'videoUrl': videoUrl,
            'timestamp': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trailer uploaded successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error uploading trailer: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading trailer: $e')));
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
      appBar: AppBar(title: const Text('Add Trailer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Trailer Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Trailer Description',
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child:
                  _thumbnail == null
                      ? Column(
                        children: const [
                          Icon(Icons.add_a_photo, size: 50),
                          SizedBox(height: 8),
                          Text('Pick Trailer Thumbnail'),
                        ],
                      )
                      : Image.file(_thumbnail!, height: 100),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickVideo,
              child:
                  _video == null
                      ? Column(
                        children: const [
                          Icon(Icons.video_library, size: 50),
                          SizedBox(height: 8),
                          Text('Pick Trailer Video'),
                        ],
                      )
                      : const Text(
                        'Trailer Video Selected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
            const SizedBox(height: 20),
            if (_isUploading) ...[
              Text('Uploading: $percentage%'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadTrailer,
              child: Text(_isUploading ? 'Uploading...' : 'Upload Trailer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen to display list of trailers, launch video URLs, and delete trailers.
class TrailerListScreen extends StatelessWidget {
  const TrailerListScreen({super.key});

  /// Launches a given URL in the default external browser.
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  /// Deletes a trailer document and its associated files from Firebase Storage.
  Future<void> _deleteTrailer(BuildContext context, String trailerId) async {
    try {
      // Define the storage paths based on trailerId.
      final thumbPath = 'trailers_thumbnails/$trailerId.png';
      final videoPath = 'trailers_videos/$trailerId.mp4';

      // Delete thumbnail and video files.
      await FirebaseStorage.instance.ref(thumbPath).delete();
      await FirebaseStorage.instance.ref(videoPath).delete();

      // Delete the trailer document from Firestore.
      await FirebaseFirestore.instance
          .collection('trailers')
          .doc(trailerId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trailer deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting trailer: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trailers'),
        actions: [
          InkWell(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTrailerScreen(),
                  ),
                ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('trailers')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading trailers'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No trailers available'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final trailerId = docs[index].id;
              final name = data['name'] ?? 'No Name';
              final description = data['description'] ?? '';
              final thumbnail = data['thumbnail'] ?? '';
              final videoUrl = data['videoUrl'] ?? '';
              return ListTile(
                leading:
                    thumbnail.isNotEmpty
                        ? Image.network(thumbnail, width: 80, fit: BoxFit.cover)
                        : null,
                title: Text(name),
                subtitle: Text(description),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: const Text('Delete Trailer'),
                            content: const Text(
                              'Are you sure you want to delete this trailer?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.of(ctx).pop();
                                  await _deleteTrailer(context, trailerId);
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    );
                  },
                ),
                onTap: () => _launchURL(videoUrl),
              );
            },
          );
        },
      ),
    );
  }
}
