import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class AddEpisodeScreen extends StatefulWidget {
  final String categoryId;
  final String videoId;

  const AddEpisodeScreen({
    super.key,
    required this.categoryId,
    required this.videoId,
  });

  @override
  _AddEpisodeScreenState createState() => _AddEpisodeScreenState();
}

class _AddEpisodeScreenState extends State<AddEpisodeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _thumbnail;
  File? _video;

  // Track if we're uploading (to show/hide progress UI & disable the upload button)
  bool _isUploading = false;

  // Track the upload progress for the video, from 0.0 -> 1.0
  double _uploadProgress = 0.0;

  /// Request media permissions for Android 13/14 and iOS.
  Future<bool> _requestMediaPermissions() async {
    if (Platform.isAndroid) {
      final photosStatus = await Permission.photos.request();
      final videosStatus = await Permission.videos.request();
      return photosStatus.isGranted && videosStatus.isGranted;
    } else {
      // For iOS, request only photos permission.
      final status = await Permission.photos.request();
      return status.isGranted;
    }
  }

  // ---------------------------------------------------------------------------
  // Pick Thumbnail (Image)
  // ---------------------------------------------------------------------------
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
        debugPrint('No thumbnail selected');
        return;
      }
      setState(() {
        _thumbnail = File(pickedFile.path);
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Pick Episode Video
  // ---------------------------------------------------------------------------
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
        debugPrint('No episode video selected');
        return;
      }
      setState(() {
        _video = File(pickedFile.path);
      });
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Upload Episode with Progress
  // ---------------------------------------------------------------------------
  Future<void> _uploadEpisode() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty ||
        description.isEmpty ||
        _thumbnail == null ||
        _video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in name, description, thumbnail, and video',
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

      final episodeId = const Uuid().v4();
      final thumbPath = 'episodes_thumbnails/$episodeId.png';
      final videoPath = 'episodes_videos/$episodeId.mp4';

      // 1. Upload thumbnail
      final thumbRef = FirebaseStorage.instance.ref(thumbPath);
      await thumbRef.putFile(_thumbnail!);
      final thumbUrl = await thumbRef.getDownloadURL();

      // 2. Upload episode video with progress tracking
      final videoRef = FirebaseStorage.instance.ref(videoPath);
      final uploadTask = videoRef.putFile(_video!);

      // Listen for progress updates
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress = progress;
        });
      });

      // Wait until the video upload completes
      await uploadTask.whenComplete(() => null);
      final videoUrl = await videoRef.getDownloadURL();

      // 3. Store Firestore document
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryId)
          .collection('videos')
          .doc(widget.videoId)
          .collection('episodes')
          .doc(episodeId)
          .set({
            'name': name,
            'description': description,
            'thumbnail': thumbUrl,
            'url': videoUrl,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Episode uploaded successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error uploading episode: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading episode: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD METHOD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final int percentage = (_uploadProgress * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Episode')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Episode Name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Episode Name'),
              ),
              // Episode Description
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Episode Description',
                ),
              ),
              const SizedBox(height: 20),
              // Pick Episode Thumbnail
              GestureDetector(
                onTap: _pickImage,
                child:
                    _thumbnail == null
                        ? Column(
                          children: const [
                            Icon(Icons.add_a_photo, size: 50),
                            SizedBox(height: 8),
                            Text('Pick Episode Thumbnail'),
                          ],
                        )
                        : Image.file(_thumbnail!, height: 100),
              ),
              const SizedBox(height: 20),
              // Pick Episode Video
              GestureDetector(
                onTap: _pickVideo,
                child:
                    _video == null
                        ? Column(
                          children: const [
                            Icon(Icons.video_library, size: 50),
                            SizedBox(height: 8),
                            Text('Pick Episode Video'),
                          ],
                        )
                        : const Text(
                          'Episode Video Selected',
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
              // Upload Button
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadEpisode,
                child: Text(_isUploading ? 'Uploading...' : 'Upload Episode'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
