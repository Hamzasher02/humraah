import 'package:adminlast/admin/episodeaddandshow.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class VideoDetailScreen extends StatefulWidget {
  final String categoryId;
  final String videoId;

  const VideoDetailScreen({
    super.key,
    required this.categoryId,
    required this.videoId,
  });

  @override
  _VideoDetailScreenState createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  String? _selectedVideoUrl;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  Future<void> _loadVideo(String videoUrl) async {
    // Dispose previous controller (if any).
    if (_videoController != null) {
      await _videoController!.dispose();
    }

    // Create a new controller for the new URL.
    final controller = VideoPlayerController.network(videoUrl);
    setState(() {
      _videoController = controller;
      _isVideoInitialized = false;
    });

    // Initialize the video (async).
    await controller.initialize();

    // Start playback automatically.
    controller.play();

    setState(() {
      _isVideoInitialized = true;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mainVideoStream =
        FirebaseFirestore.instance
            .collection('categories')
            .doc(widget.categoryId)
            .collection('videos')
            .doc(widget.videoId)
            .snapshots();

    final episodesStream =
        FirebaseFirestore.instance
            .collection('categories')
            .doc(widget.categoryId)
            .collection('videos')
            .doc(widget.videoId)
            .collection('episodes')
            .orderBy('timestamp', descending: true)
            .snapshots();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: mainVideoStream,
          builder: (context, mainSnapshot) {
            if (mainSnapshot.hasError) {
              return Center(child: Text('Error: ${mainSnapshot.error}'));
            }
            if (!mainSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final mainDoc = mainSnapshot.data!;
            if (!mainDoc.exists) {
              return const Center(child: Text('Main video not found.'));
            }

            final mainData = mainDoc.data() as Map<String, dynamic>;
            final parentVideoUrl = mainData['url'] as String?;
            final coverImage =
                mainData['coverImage'] ??
                'https://via.placeholder.com/600x400?text=No+Cover+Image';
            final title = mainData['title'] ?? 'No Title';
            final description =
                mainData['description'] ?? 'No description available.';

            return StreamBuilder<QuerySnapshot>(
              stream: episodesStream,
              builder: (ctx, episodesSnapshot) {
                if (episodesSnapshot.hasError) {
                  return Center(
                    child: Text('Error: ${episodesSnapshot.error}'),
                  );
                }
                if (!episodesSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final episodes = episodesSnapshot.data!.docs;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- TOP AREA ---
                      if (_selectedVideoUrl == null)
                        Stack(
                          children: [
                            Image.network(
                              coverImage,
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 50,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black54,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 20,
                              left: 16,
                              child: Text(
                                title.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        // The small player in portrait (or fixed width in landscape)
                        _buildVideoPlayerArea(),

                      const SizedBox(height: 8),

                      // --- PLAY BUTTON ---
                      if (_selectedVideoUrl == null && parentVideoUrl != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(42),
                            ),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play'),
                            onPressed: () {
                              setState(() {
                                _selectedVideoUrl = parentVideoUrl;
                              });
                              _loadVideo(parentVideoUrl);
                            },
                          ),
                        ),

                      // --- ABOUT SECTION ---
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- EPISODES HEADER ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Episodes',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // --- EPISODES LIST ---
                      ListView.builder(
                        itemCount: episodes.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final doc = episodes[index];
                          final data = doc.data() as Map<String, dynamic>;

                          final epName = data['name'] ?? 'No Name';
                          final epDesc = data['description'] ?? '';
                          final epThumb = data['thumbnail'] as String?;
                          final epUrl = data['url'] as String?;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child:
                                    epThumb != null
                                        ? Image.network(
                                          epThumb,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        )
                                        : const Icon(
                                          Icons.image_not_supported,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                              ),
                              title: Text(
                                epName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                epDesc,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  if (epUrl != null) {
                                    setState(() {
                                      _selectedVideoUrl = epUrl;
                                    });
                                    _loadVideo(epUrl);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AddEpisodeScreen(
                    categoryId: widget.categoryId,
                    videoId: widget.videoId,
                  ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// In portrait mode, the video is smaller (e.g., 1/3 screen).
  /// In landscape, we center it with a fixed width (e.g., 600).
  Widget _buildVideoPlayerArea() {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    if (isPortrait) {
      // One-third screen height
      return SizedBox(
        height: MediaQuery.of(context).size.height / 3,
        width: double.infinity,
        child:
            _videoController == null
                ? const Center(
                  child: Text(
                    'Loading video...',
                    style: TextStyle(color: Colors.white),
                  ),
                )
                : _isVideoInitialized
                ? _CustomVideoPlayer(controller: _videoController!)
                : const Center(child: CircularProgressIndicator()),
      );
    } else {
      // Landscape - fixed width, e.g. 600 px
      final aspect =
          _isVideoInitialized
              ? _videoController?.value.aspectRatio ?? 16 / 9
              : 16 / 9;
      return Center(
        child: SizedBox(
          width: 600,
          child: AspectRatio(
            aspectRatio: aspect,
            child:
                _videoController == null
                    ? const Center(
                      child: Text(
                        'Loading video...',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                    : _isVideoInitialized
                    ? _CustomVideoPlayer(controller: _videoController!)
                    : const Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }
  }
}

/// Custom overlay in the small player.
/// The user can tap fullscreen to open `_FullScreenVideoPlayer`.
class _CustomVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  const _CustomVideoPlayer({required this.controller});

  @override
  State<_CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<_CustomVideoPlayer> {
  bool _showControls = true;

  void _goFullScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => _FullScreenVideoPlayer(controller: widget.controller),
      ),
    );
  }

  void _skip(int seconds) {
    final currentPos = widget.controller.value.position;
    widget.controller.seekTo(currentPos + Duration(seconds: seconds));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Stack(
        children: [
          // The actual video
          VideoPlayer(widget.controller),

          // If controls are visible, show them
          if (_showControls) ...[
            // Center play/pause
            Positioned.fill(
              child: Center(
                child: IconButton(
                  iconSize: 64,
                  icon: Icon(
                    widget.controller.value.isPlaying
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                  ),
                  color: Colors.white,
                  onPressed: () {
                    setState(() {
                      if (widget.controller.value.isPlaying) {
                        widget.controller.pause();
                      } else {
                        widget.controller.play();
                      }
                    });
                  },
                ),
              ),
            ),

            // Skip back 10s
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  iconSize: 48,
                  icon: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.replay_10, color: Colors.white),
                      SizedBox(height: 4),
                      Text("10", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  onPressed: () => _skip(-10),
                ),
              ),
            ),

            // Skip forward 10s
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  iconSize: 48,
                  icon: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.forward_10, color: Colors.white),
                      SizedBox(height: 4),
                      Text("10", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  onPressed: () => _skip(10),
                ),
              ),
            ),

            // Fullscreen button (bottom-right)
            Positioned(
              bottom: 16,
              right: 16,
              child: IconButton(
                iconSize: 30,
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: _goFullScreen,
              ),
            ),

            // Bottom progress bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VideoProgressIndicator(
                    widget.controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.red,
                      bufferedColor: Colors.white54,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(widget.controller.value.position),
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          _formatDuration(widget.controller.value.duration),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final secs = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${_twoDigits(hours)}:${_twoDigits(minutes)}:${_twoDigits(secs)}';
    } else {
      return '${_twoDigits(minutes)}:${_twoDigits(secs)}';
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}

/// Full-screen video player with the **same** overlay in landscape.
class _FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  const _FullScreenVideoPlayer({required this.controller});

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // Force device orientation to landscape.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Reset orientation after leaving.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _skip(int seconds) {
    final currentPos = widget.controller.value.position;
    widget.controller.seekTo(currentPos + Duration(seconds: seconds));
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final secs = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${_twoDigits(hours)}:${_twoDigits(minutes)}:${_twoDigits(secs)}';
    } else {
      return '${_twoDigits(minutes)}:${_twoDigits(secs)}';
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // We can skip the floatingActionButton and replicate the same overlay logic:
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showControls = !_showControls;
            });
          },
          child: Stack(
            children: [
              // Full screen video
              Center(
                child: AspectRatio(
                  aspectRatio: widget.controller.value.aspectRatio,
                  child: VideoPlayer(widget.controller),
                ),
              ),

              if (_showControls) ...[
                // Center play/pause
                Positioned.fill(
                  child: Center(
                    child: IconButton(
                      iconSize: 64,
                      icon: Icon(
                        widget.controller.value.isPlaying
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                      ),
                      color: Colors.white,
                      onPressed: () {
                        setState(() {
                          if (widget.controller.value.isPlaying) {
                            widget.controller.pause();
                          } else {
                            widget.controller.play();
                          }
                        });
                      },
                    ),
                  ),
                ),

                // Skip back 10s
                Positioned(
                  left: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      iconSize: 48,
                      icon: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.replay_10, color: Colors.white),
                          SizedBox(height: 4),
                          Text("10", style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      onPressed: () => _skip(-10),
                    ),
                  ),
                ),

                // Skip forward 10s
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      iconSize: 48,
                      icon: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.forward_10, color: Colors.white),
                          SizedBox(height: 4),
                          Text("10", style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      onPressed: () => _skip(10),
                    ),
                  ),
                ),

                // Bottom progress bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      VideoProgressIndicator(
                        widget.controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Colors.red,
                          bufferedColor: Colors.white54,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(widget.controller.value.position),
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              _formatDuration(widget.controller.value.duration),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
