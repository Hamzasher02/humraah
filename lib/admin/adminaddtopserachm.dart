import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminMovieScreen extends StatefulWidget {
  const AdminMovieScreen({super.key});

  @override
  _AdminMovieScreenState createState() => _AdminMovieScreenState();
}

class _AdminMovieScreenState extends State<AdminMovieScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Request permissions for media and camera.
  Future<bool> _requestPermission() async {
    bool mediaGranted = false;
    if (Platform.isAndroid) {
      final photosStatus = await Permission.photos.request();
      final videosStatus = await Permission.videos.request();
      mediaGranted = photosStatus.isGranted && videosStatus.isGranted;
    } else {
      final photosStatus = await Permission.photos.request();
      mediaGranted = photosStatus.isGranted;
    }
    final cameraStatus = await Permission.camera.request();
    final cameraGranted = cameraStatus.isGranted;
    return mediaGranted && cameraGranted;
  }

  /// Show a dialog for adding/editing a movie.
  Future<void> _showAddMovieDialog({DocumentSnapshot? movieDoc}) async {
    final TextEditingController nameController = TextEditingController(
      text: movieDoc != null ? movieDoc.get('name') : '',
    );
    XFile? thumbnail;
    FilePickerResult? video;
    double progress = 0.0;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder:
          (context, animation, secondaryAnimation) => StatefulBuilder(
            builder:
                (context, setState) => Align(
                  alignment: Alignment.topCenter,
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50.0),
                      child: AlertDialog(
                        title: Text(
                          movieDoc == null ? 'Add Movie' : 'Edit Movie',
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Movie Name',
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  // Request permission before picking thumbnail.
                                  final granted = await _requestPermission();
                                  if (!granted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Permissions not granted',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  thumbnail = await _imagePicker.pickImage(
                                    source: ImageSource.gallery,
                                  );
                                  setState(() {});
                                },
                                child: Text(
                                  thumbnail == null
                                      ? 'Pick Thumbnail'
                                      : 'Thumbnail Selected',
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  // Request permission before picking video.
                                  final granted = await _requestPermission();
                                  if (!granted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Permissions not granted',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  video = await FilePicker.platform.pickFiles(
                                    type: FileType.video,
                                  );
                                  setState(() {});
                                },
                                child: Text(
                                  video == null
                                      ? 'Pick Video'
                                      : 'Video Selected',
                                ),
                              ),
                              if (progress > 0)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: LinearProgressIndicator(
                                    value: progress / 100,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (nameController.text.isNotEmpty) {
                                String? thumbUrl = movieDoc?.get('thumbnail');
                                String? videoUrl = movieDoc?.get('video');

                                if (thumbnail != null) {
                                  var thumbRef = _storage.ref().child(
                                    'thumbnails/${thumbnail!.name}',
                                  );
                                  var thumbUpload = thumbRef.putData(
                                    await thumbnail!.readAsBytes(),
                                  );
                                  thumbUrl =
                                      await (await thumbUpload).ref
                                          .getDownloadURL();
                                }

                                if (video != null) {
                                  var videoRef = _storage.ref().child(
                                    'videos/${video!.files.single.name}',
                                  );
                                  var videoUpload = videoRef.putFile(
                                    File(video!.files.single.path!),
                                  );
                                  videoUrl =
                                      await (await videoUpload).ref
                                          .getDownloadURL();
                                }

                                if (movieDoc == null) {
                                  await _firestore.collection('movies').add({
                                    'name': nameController.text,
                                    'thumbnail': thumbUrl,
                                    'video': videoUrl,
                                  });
                                } else {
                                  await _firestore
                                      .collection('movies')
                                      .doc(movieDoc.id)
                                      .update({
                                        'name': nameController.text,
                                        'thumbnail': thumbUrl,
                                        'video': videoUrl,
                                      });
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Movie ${movieDoc == null ? 'Added' : 'Updated'} Successfully',
                                    ),
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            },
                            child: Text(movieDoc == null ? 'Upload' : 'Update'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  /// Delete a movie and its associated files.
  Future<void> _deleteMovie(DocumentSnapshot movieDoc) async {
    try {
      final thumbnailUrl = movieDoc['thumbnail'] as String?;
      if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(thumbnailUrl).delete();
        } catch (e) {
          debugPrint('Thumbnail deletion error (might be already deleted): $e');
        }
      }
      final videoUrl = movieDoc['video'] as String?;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(videoUrl).delete();
        } catch (e) {
          debugPrint('Video deletion error (might be already deleted): $e');
        }
      }
      await _firestore.collection('movies').doc(movieDoc.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Movie Deleted Successfully')),
      );
    } catch (e) {
      debugPrint('Error deleting movie: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting movie: $e')));
    }
  }

  /// Launch the video URL using url_launcher.
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Movies')),
      body: StreamBuilder(
        stream: _firestore.collection('movies').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No movies available'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var movie = snapshot.data!.docs[index];
              Widget leadingWidget;
              if (movie['thumbnail'] != null &&
                  (movie['thumbnail'] as String).isNotEmpty) {
                leadingWidget = Image.network(
                  movie['thumbnail'],
                  width: 80,
                  fit: BoxFit.cover,
                );
              } else {
                leadingWidget = const Icon(Icons.movie, size: 80);
              }
              return ListTile(
                leading: leadingWidget,
                title: Text(movie['name']),
                subtitle: const Text('Tap to play video'),
                onTap: () {
                  if (movie['video'] != null &&
                      (movie['video'] as String).isNotEmpty) {
                    _launchURL(movie['video']);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No video available')),
                    );
                  }
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showAddMovieDialog(movieDoc: movie),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteMovie(movie),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMovieDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
