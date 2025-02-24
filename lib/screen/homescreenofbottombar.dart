import 'dart:async';

import 'package:adminlast/screen/videoplayscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'profile.dart';
import 'search_screen.dart';

/// A helper widget to load images safely from network or asset.
/// If the image fails to load, it shows an error icon.
class SafeImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;

  const SafeImage({super.key, required this.imageUrl, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.error, color: Colors.red));
        },
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.error, color: Colors.red));
        },
      );
    }
  }
}

/// BannerSection widget for the top banner area.
/// Initially displays the SafeImage with gradient overlay and a Play button.
/// When the Play button is pressed, it fetches the latest trailer from Firestore,
/// initializes the video controller, and replaces the image with the video.
/// Additionally, tapping the video toggles between pause and play.
class BannerSection extends StatefulWidget {
  const BannerSection({super.key});

  @override
  _BannerSectionState createState() => _BannerSectionState();
}

class _BannerSectionState extends State<BannerSection> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlayingVideo = false;

  Future<void> _playTrailerVideo() async {
    // Immediately hide the play button.
    setState(() {
      _isPlayingVideo = true;
    });
    // Fetch the latest trailer video from Firestore.
    final trailerSnapshot =
        await FirebaseFirestore.instance
            .collection('trailers')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
    if (trailerSnapshot.docs.isNotEmpty) {
      final trailerData = trailerSnapshot.docs.first.data();
      final videoUrl = trailerData['videoUrl'] as String;
      // Initialize the VideoPlayerController with the fetched URL.
      _controller = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          setState(() {
            _isInitialized = true;
          });
          _controller?.setLooping(true);
          _controller?.play();
        });
    } else {
      setState(() {
        _isPlayingVideo = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No trailer available.")));
    }
  }

  // Toggle play/pause when video is tapped.
  void _togglePlayPause() {
    if (_controller != null) {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show the play button only when video is not loaded.
    bool showPlayButton = !_isPlayingVideo;
    return ClipRect(
      child: Stack(
        children: [
          SizedBox(
            height: 450,
            width: double.infinity,
            child:
                _isPlayingVideo && _isInitialized && _controller != null
                    ? GestureDetector(
                      onTap: _togglePlayPause,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.size.width,
                          height: _controller!.value.size.height,
                          child: VideoPlayer(_controller!),
                        ),
                      ),
                    )
                    : const SafeImage(
                      imageUrl: 'assets/drama1.jpeg',
                      fit: BoxFit.cover,
                    ),
          ),
          Container(
            height: 450,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                  Colors.black,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          if (showPlayButton)
            Positioned(
              bottom: 80,
              left: MediaQuery.of(context).size.width / 2 - 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: _playTrailerVideo,
                icon: const Icon(
                  Icons.play_arrow,
                  size: 20,
                  color: Colors.black,
                ),
                label: const Text(
                  "Play",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SafeImage(imageUrl: 'assets/logo.png', fit: BoxFit.contain),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            icon: const Icon(Icons.search, color: Colors.red),
          ),
          PopupMenuButton<int>(
            color: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            icon: const Icon(Icons.more_vert, color: Colors.red),
            onSelected: (int value) {
              if (value == 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Change Language Selected")),
                );
              } else if (value == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  PopupMenuItem<int>(
                    value: 1,
                    child: Row(
                      children: const [
                        Icon(Icons.language, color: Colors.red),
                        SizedBox(width: 10),
                        Text(
                          'Change Language',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 2,
                    child: Row(
                      children: const [
                        Icon(Icons.person, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Profile', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Banner Section with inline video playback
            const BannerSection(),

            // Dynamic Stories Section (fetched from Firestore)
            buildStoriesSection(context),

            // Continue Watching Section (dummy data)
            buildContinueWatchingSection(context, "Continue Watching", [
              {
                'image': 'assets/drama1.jpeg',
                'url': 'https://example.com/video6.mp4',
              },
              {
                'image': 'assets/drama2.jpeg',
                'url': 'https://example.com/video7.mp4',
              },
              {
                'image': 'assets/drama3.jpeg',
                'url': 'https://example.com/video8.mp4',
              },
              {
                'image': 'assets/drama4.jpeg',
                'url': 'https://example.com/video9.mp4',
              },
            ]),

            // Dynamic Categories from Firestore (existing implementation)
            _buildDynamicCategories(context),
          ],
        ),
      ),
    );
  }

  /// Build the Stories section by streaming the "stories" collection.
  Widget buildStoriesSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('stories')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading stories: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final storiesDocs = snapshot.data!.docs;
        if (storiesDocs.isEmpty) {
          return const SizedBox(); // No stories to display.
        }

        // Prepare a list of story data.
        final List<Map<String, dynamic>> storiesList =
            storiesDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return {
                'mediaUrl': data?['mediaUrl'] as String? ?? '',
                'mediaType': data?['mediaType'] as String? ?? 'image',
              };
            }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section heading.
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 10,
              ),
              child: Text(
                "Stories",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Horizontal list of stories.
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: storiesList.length,
                itemBuilder: (context, index) {
                  final story = storiesList[index];
                  final mediaUrl = story['mediaUrl'] as String;
                  final mediaType = story['mediaType'] as String;
                  return GestureDetector(
                    onTap: () {
                      // Open the StoryViewerScreen starting at the tapped index.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => StoryViewerScreen(
                                stories: storiesList,
                                initialIndex: index,
                              ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red, width: 2),
                        image: DecorationImage(
                          image:
                              mediaUrl.startsWith('http')
                                  ? NetworkImage(mediaUrl)
                                  : AssetImage(mediaUrl) as ImageProvider,
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        ),
                      ),
                      child:
                          mediaType == 'video'
                              ? const Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              )
                              : null,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Continue Watching Section (dummy data)
  Widget buildContinueWatchingSection(
    BuildContext context,
    String title,
    List<Map<String, String>> videos,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  // Dummy action for continue watching.
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 120,
                              width: double.infinity,
                              child: SafeImage(
                                imageUrl: videos[index]['image']!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            height: 40,
                            color: Colors.black87,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        videos[index]['title'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Dynamic Categories from Firestore.
  Widget _buildDynamicCategories(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (ctx, catSnapshot) {
        if (catSnapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading categories: ${catSnapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }
        if (!catSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final categoryDocs = catSnapshot.data!.docs;
        if (categoryDocs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No categories found.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              categoryDocs.map((catDoc) {
                final catData = catDoc.data() as Map<String, dynamic>?;
                if (catData == null) return const SizedBox();
                final catName = catData['name'] ?? 'No Name';
                final catId = catDoc.id;
                return StreamBuilder<QuerySnapshot>(
                  stream: catDoc.reference.collection('videos').snapshots(),
                  builder: (ctx, vidSnapshot) {
                    if (vidSnapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error loading videos for $catName: ${vidSnapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    if (!vidSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final videoDocs = vidSnapshot.data!.docs;
                    if (videoDocs.isEmpty) return const SizedBox();
                    final videoList =
                        videoDocs.map<Map<String, String>>((vDoc) {
                          final vData = vDoc.data() as Map<String, dynamic>?;
                          final vidId = vDoc.id;
                          return {
                            'id': vidId,
                            'image':
                                (vData?['thumbnail'] ?? 'assets/drama1.jpeg')
                                    .toString(),
                            'url': (vData?['url'] ?? '').toString(),
                            'title': (vData?['name'] ?? 'No Title').toString(),
                          };
                        }).toList();
                    return buildCategorySection(ctx, catName, videoList, catId);
                  },
                );
              }).toList(),
        );
      },
    );
  }

  // Build rectangular category section.
  Widget buildCategorySection(
    BuildContext context,
    String title,
    List<Map<String, String>> videos,
    String categoryId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 150,
          // width: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final imageUrl = videos[index]['image']!;
              final videoId = videos[index]['id']!;
              return GestureDetector(
                onTap: () {
                  // Navigate to UserSideVideoDetailScreen with selected video.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (ctx) => UserSideVideoDetailScreen(
                            categoryId: categoryId,
                            videoId: videoId,
                          ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SafeImage(imageUrl: imageUrl, fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Story Viewer Screen – plays a series of stories (image or video)
/// similar to Instagram. Images auto-advance after 5 seconds and videos
/// auto-advance when completed. Tapping left/right moves between stories.
class StoryViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;
  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  _StoryViewerScreenState createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late int currentIndex;
  Timer? _timer;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // Duration for image stories.
  final Duration imageDuration = const Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _loadCurrentStory();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadCurrentStory() {
    _timer?.cancel();
    _videoController?.dispose();
    _isVideoInitialized = false;

    final currentStory = widget.stories[currentIndex];
    final mediaUrl = currentStory['mediaUrl'] as String;
    final mediaType = currentStory['mediaType'] as String;

    if (mediaType == 'video') {
      _videoController = VideoPlayerController.network(mediaUrl)
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController!.play();
          // Listen for video end to auto-advance.
          _videoController!.addListener(() {
            if (_videoController!.value.position >=
                    _videoController!.value.duration &&
                mounted) {
              _nextStory();
            }
          });
        });
    } else {
      // For images, auto-advance after a fixed duration.
      _timer = Timer(imageDuration, () {
        _nextStory();
      });
    }
  }

  void _nextStory() {
    if (currentIndex < widget.stories.length - 1) {
      setState(() {
        currentIndex++;
      });
      _loadCurrentStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
      _loadCurrentStory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStory = widget.stories[currentIndex];
    final mediaUrl = currentStory['mediaUrl'] as String;
    final mediaType = currentStory['mediaType'] as String;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          final dx = details.globalPosition.dx;
          if (dx < width / 3) {
            _previousStory();
          } else if (dx > 2 * width / 3) {
            _nextStory();
          }
        },
        child: Stack(
          children: [
            Center(
              child:
                  mediaType == 'video'
                      ? (_isVideoInitialized
                          ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                          : const CircularProgressIndicator())
                      : SafeImage(imageUrl: mediaUrl, fit: BoxFit.contain),
            ),
            // Progress indicator.
            Positioned(
              top: 40,
              left: 10,
              right: 10,
              child: Row(
                children:
                    widget.stories.map((story) {
                      int index = widget.stories.indexOf(story);
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 3,
                          decoration: BoxDecoration(
                            color:
                                index < currentIndex
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            // Close button.
            Positioned(
              top: 40,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
