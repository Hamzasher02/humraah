import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class AdminAddStoryScreen extends StatefulWidget {
  const AdminAddStoryScreen({super.key});

  @override
  State<AdminAddStoryScreen> createState() => _AdminAddStoryScreenState();
}

class _AdminAddStoryScreenState extends State<AdminAddStoryScreen> {
  // For caption, we use one field like WhatsApp.
  final TextEditingController _captionController = TextEditingController();
  File? _mediaFile; // Selected media file (image or video)
  String? _mediaType; // 'image' or 'video'
  bool _isUploading = false;

  /// Request storage (and camera) permission.
  Future<bool> _requestPermission() async {
    final status = await Permission.storage.request();
    final cameraStatus = await Permission.camera.request();
    return status.isGranted && cameraStatus.isGranted;
  }

  /// Show a dialog to choose media source and type.
  Future<void> _pickMedia() async {
    final granted = await _requestPermission();
    if (!granted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Permissions not granted')));
      return;
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Media'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'gallery_image'),
              child: const Text('Gallery Image'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'camera_image'),
              child: const Text('Camera Image'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'gallery_video'),
              child: const Text('Gallery Video'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'camera_video'),
              child: const Text('Camera Video'),
            ),
          ],
        );
      },
    );
    if (choice == null) return;

    final picker = ImagePicker();
    XFile? pickedFile;
    if (choice == 'gallery_image') {
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
      _mediaType = 'image';
    } else if (choice == 'camera_image') {
      pickedFile = await picker.pickImage(source: ImageSource.camera);
      _mediaType = 'image';
    } else if (choice == 'gallery_video') {
      pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      _mediaType = 'video';
    } else if (choice == 'camera_video') {
      pickedFile = await picker.pickVideo(source: ImageSource.camera);
      _mediaType = 'video';
    }
    if (pickedFile != null) {
      setState(() {
        _mediaFile = File(pickedFile!.path);
      });
    }
  }

  /// Upload the story: first upload media to Firebase Storage, then create Firestore doc.
  Future<void> _uploadStory() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty || _mediaFile == null || _mediaType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select media and enter a caption.'),
        ),
      );
      return;
    }
    setState(() {
      _isUploading = true;
    });
    try {
      final storyId = const Uuid().v4();
      String mediaPath;
      if (_mediaType == 'image') {
        mediaPath = 'stories_images/$storyId.jpg';
      } else {
        mediaPath = 'stories_videos/$storyId.mp4';
      }
      final mediaRef = FirebaseStorage.instance.ref(mediaPath);
      await mediaRef.putFile(_mediaFile!);
      final mediaUrl = await mediaRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('stories').doc(storyId).set({
        'caption': caption,
        'mediaUrl': mediaUrl,
        'mediaType': _mediaType, // "image" or "video"
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story added successfully!')),
      );

      // Clear fields
      _captionController.clear();
      setState(() {
        _mediaFile = null;
        _mediaType = null;
      });
    } catch (e) {
      debugPrint('Error uploading story: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload story: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a dark full-screen background
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Add Status'),
      ),
      body: Stack(
        children: [
          // If media is selected, show full-screen preview; otherwise, show a placeholder.
          _mediaFile != null
              ? _mediaType == 'image'
                  ? Image.file(
                    _mediaFile!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                  : Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 100,
                      ),
                    ),
                  )
              : Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.grey.shade900,
                child: const Center(
                  child: Text(
                    'Tap the icon to add media',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
          // A dark overlay for readability.
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.3),
          ),
          // Top-right: Button to pick media (like WhatsApp status add icon)
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: const Icon(
                Icons.add_photo_alternate,
                color: Colors.white,
                size: 30,
              ),
              onPressed: _pickMedia,
            ),
          ),
          // Bottom caption input and send button (overlaid on media)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _captionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter your status caption...',
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.black54,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isUploading ? null : _uploadStory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Send',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
