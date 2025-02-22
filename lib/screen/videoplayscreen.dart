import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';

class UserSideVideoDetailScreen extends StatefulWidget {
  final String categoryId;
  final String videoId;

  const UserSideVideoDetailScreen({
    super.key,
    required this.categoryId,
    required this.videoId,
  });

  @override
  State<UserSideVideoDetailScreen> createState() =>
      _UserSideVideoDetailScreenState();
}

class _UserSideVideoDetailScreenState extends State<UserSideVideoDetailScreen> {
  // Video controllers
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  // Firestore data
  String _title = '';
  String _description = '';
  String _videoUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVideoData();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _fetchVideoData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('categories')
              .doc(widget.categoryId)
              .collection('videos')
              .doc(widget.videoId)
              .get();

      if (!doc.exists) {
        // If no document found, just stop loading
        setState(() => _isLoading = false);
        return;
      }

      final data = doc.data()!;
      _title = data['name'] ?? 'No Title';
      _description = data['description'] ?? 'No description provided.';
      _videoUrl = data['url'] ?? '';

      // Initialize video
      _videoPlayerController = VideoPlayerController.network(_videoUrl);
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        deviceOrientationsOnEnterFullScreen: [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
      );

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetching video data: $e');
      setState(() => _isLoading = false);
    }
  }

  // When user taps an episode, we re-initialize the player with that episode’s URL
  Future<void> _playEpisode(String episodeUrl) async {
    setState(() => _isLoading = true);
    await _videoPlayerController?.pause();
    await _videoPlayerController?.dispose();
    _chewieController?.dispose();

    _videoPlayerController = VideoPlayerController.network(episodeUrl);
    await _videoPlayerController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      deviceOrientationsOnEnterFullScreen: [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
    );

    setState(() => _isLoading = false);
  }

  // Helper widget to build the video player that always fills the screen width.
  // In portrait mode, a fixed (reduced) height is used.
  // In landscape, the height is computed based on the video's aspect ratio.
  Widget _buildVideoPlayer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (isPortrait) {
      // For portrait mode, we use a fixed height (adjust the multiplier as needed)
      return SizedBox(
        width: screenWidth,
        height: screenWidth * 0.8, // Full width with fixed height (adjustable)
        child: Chewie(controller: _chewieController!),
      );
    } else {
      // For landscape mode, we calculate the height based on the video's aspect ratio
      final aspectRatio = _videoPlayerController!.value.aspectRatio;
      return SizedBox(
        width: screenWidth,
        height: screenWidth / aspectRatio,
        child: Chewie(controller: _chewieController!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // If you want no AppBar, you can remove it or customize as needed.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_title),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBodyContent(context),
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top Banner with Video Player & Overlays ---
          Stack(
            children: [
              // Use our custom _buildVideoPlayer widget that fills the screen width.
              _buildVideoPlayer(context),
              // A gradient overlay at the bottom (like Netflix style)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.0),
                        Colors.black,
                      ],
                      begin: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Play button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () {
              // Example: enter full screen
              _chewieController!.enterFullScreen();
            },
            icon: const Icon(Icons.play_arrow, color: Colors.black),
            label: const Text("Play", style: TextStyle(color: Colors.black)),
          ),
          // Video title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              _title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
            ),
          ),
          // --- About Section ---
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 12),
            child: Text(
              "About",
              style: const TextStyle(
                color: Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Text(
              _description,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          // --- Episodes List ---
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
            child: Text(
              "Episodes",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildEpisodesList(context),
        ],
      ),
    );
  }

  /// Builds a vertical list of episodes.
  /// Each item includes a thumbnail, the episode title, and a play icon.
  Widget _buildEpisodesList(BuildContext context) {
    // Episodes subcollection path:
    // categories -> doc(widget.categoryId) -> videos -> doc(widget.videoId) -> episodes
    final episodesRef = FirebaseFirestore.instance
        .collection('categories')
        .doc(widget.categoryId)
        .collection('videos')
        .doc(widget.videoId)
        .collection('episodes');

    return StreamBuilder<QuerySnapshot>(
      stream: episodesRef.snapshots(),
      builder: (ctx, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading episodes: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No episodes found.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final epName = data['name'] ?? 'Episode ${index + 1}';
            final epUrl = data['url'] ?? '';
            final epThumbnail =
                data['thumbnail'] ??
                'https://via.placeholder.com/150/000000/FFFFFF?text=Episode';

            return InkWell(
              onTap: () => _playEpisode(epUrl),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Thumbnail on left
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        epThumbnail,
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Episode title
                    Expanded(
                      child: Text(
                        epName,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Play icon on the right
                    IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.red),
                      onPressed: () => _playEpisode(epUrl),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
