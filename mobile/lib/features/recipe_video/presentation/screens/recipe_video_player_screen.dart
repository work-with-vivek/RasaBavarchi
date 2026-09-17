import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class RecipeVideoPlayerScreen extends StatefulWidget {
  const RecipeVideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.recipeTitle,
  });

  final String videoUrl;
  final String recipeTitle;

  @override
  State<RecipeVideoPlayerScreen> createState() =>
      _RecipeVideoPlayerScreenState();
}

class _RecipeVideoPlayerScreenState extends State<RecipeVideoPlayerScreen> {
  VideoPlayerController? _controller;

  bool _isInitializing = true;
  bool _hasError = false;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  // ===========================================================
  // INITIALIZE VIDEO
  // ===========================================================

  Future<void> _initializeVideo() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      _controller = controller;

      await controller.initialize();

      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitializing = false;
        _hasError = true;
      });
    }
  }

  // ===========================================================
  // DISPOSE
  // ===========================================================

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _controller?.dispose();

    super.dispose();
  }

  // ===========================================================
  // PLAY / PAUSE
  // ===========================================================

  void _togglePlayback() {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  // ===========================================================
  // RESTART
  // ===========================================================

  Future<void> _restartVideo() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    await controller.seekTo(Duration.zero);

    await controller.play();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ===========================================================
  // MUTE / UNMUTE
  // ===========================================================

  Future<void> _toggleMute() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final isMuted = controller.value.volume == 0;

    await controller.setVolume(isMuted ? 1.0 : 0.0);

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ===========================================================
  // FULLSCREEN
  // ===========================================================

  Future<void> _enterFullscreen() async {
    if (_isFullscreen) {
      return;
    }

    setState(() {
      _isFullscreen = true;
    });

    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // ===========================================================
  // EXIT FULLSCREEN
  // ===========================================================

  Future<void> _exitFullscreen() async {
    if (!_isFullscreen) {
      return;
    }

    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (!mounted) {
      return;
    }

    setState(() {
      _isFullscreen = false;
    });
  }

  // ===========================================================
  // FORMAT DURATION
  // ===========================================================

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return _buildFullscreenScaffold(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recipeTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  // ===========================================================
  // BODY
  // ===========================================================

  Widget _buildBody(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return _buildError();
    }

    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: Text('Video is not available.'));
    }

    return Column(
      children: [
        _buildVideoSection(context, controller, fullscreen: false),
        _buildControls(context, controller, fullscreen: false),
        Expanded(child: _buildVideoInformation(context)),
      ],
    );
  }

  // ===========================================================
  // ERROR
  // ===========================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Unable to play this video.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'The generated video could not be loaded.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // VIDEO SECTION
  // ===========================================================

  Widget _buildVideoSection(
    BuildContext context,
    VideoPlayerController controller, {
    required bool fullscreen,
  }) {
    final value = controller.value;

    final aspectRatio = value.aspectRatio > 0 ? value.aspectRatio : 16 / 9;

    if (fullscreen) {
      return Expanded(
        child: Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: _buildVideoStack(context, controller, fullscreen: true),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: _buildVideoStack(context, controller, fullscreen: false),
    );
  }

  // ===========================================================
  // VIDEO STACK
  // ===========================================================

  Widget _buildVideoStack(
    BuildContext context,
    VideoPlayerController controller, {
    required bool fullscreen,
  }) {
    final value = controller.value;

    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: VideoPlayer(controller)),

          // ================================================
          // CENTER PLAY / PAUSE
          // ================================================
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _togglePlayback,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: value.isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: fullscreen ? 76 : 68,
                      height: fullscreen ? 76 : 68,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: fullscreen ? 44 : 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ================================================
          // TOP RIGHT FULLSCREEN
          // ================================================
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: IconButton.filledTonal(
                tooltip: fullscreen ? 'Exit full screen' : 'Full screen',
                onPressed: fullscreen ? _exitFullscreen : _enterFullscreen,
                icon: Icon(
                  fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // CONTROLS
  // ===========================================================

  Widget _buildControls(
    BuildContext context,
    VideoPlayerController controller, {
    required bool fullscreen,
  }) {
    final value = controller.value;

    return Container(
      color: fullscreen
          ? Colors.black
          : Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(
        fullscreen ? 24 : 16,
        8,
        fullscreen ? 24 : 16,
        fullscreen ? 16 : 8,
      ),
      child: Column(
        children: [
          // ================================================
          // PROGRESS
          // ================================================

          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),

          const SizedBox(height: 5),

          // ================================================
          // TIME
          // ================================================
          Row(
            children: [
              Text(
                _formatDuration(value.position),
                style: TextStyle(
                  color: fullscreen ? Colors.white : null,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                _formatDuration(value.duration),
                style: TextStyle(
                  color: fullscreen ? Colors.white : null,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ================================================
          // BUTTONS
          // ================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Restart',
                onPressed: _restartVideo,
                icon: Icon(
                  Icons.replay,
                  color: fullscreen ? Colors.white : null,
                ),
              ),

              const SizedBox(width: 12),

              IconButton.filled(
                tooltip: value.isPlaying ? 'Pause' : 'Play',
                onPressed: _togglePlayback,
                icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
              ),

              const SizedBox(width: 12),

              IconButton(
                tooltip: value.volume == 0 ? 'Unmute' : 'Mute',
                onPressed: _toggleMute,
                icon: Icon(
                  value.volume == 0 ? Icons.volume_off : Icons.volume_up,
                  color: fullscreen ? Colors.white : null,
                ),
              ),

              const SizedBox(width: 12),

              if (!fullscreen)
                IconButton(
                  tooltip: 'Full screen',
                  onPressed: _enterFullscreen,
                  icon: const Icon(Icons.fullscreen),
                )
              else
                IconButton(
                  tooltip: 'Exit full screen',
                  onPressed: _exitFullscreen,
                  icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // VIDEO INFORMATION
  // ===========================================================

  Widget _buildVideoInformation(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.recipeTitle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generated recipe video',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            context,
            icon: Icons.movie_creation_outlined,
            title: 'Recipe Video',
            text:
                'Watch the AI-generated explanation '
                'for this recipe.',
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // INFORMATION CARD
  // ===========================================================

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String text,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(text, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // FULLSCREEN SCAFFOLD
  // ===========================================================

  Widget _buildFullscreenScaffold(BuildContext context) {
    final controller = _controller;

    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_hasError) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Unable to play this video.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Video is not available.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildVideoSection(context, controller, fullscreen: true),
            _buildControls(context, controller, fullscreen: true),
          ],
        ),
      ),
    );
  }
}
