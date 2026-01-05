import 'package:flutter/material.dart';
import 'package:better_player/better_player.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VideoPlayerContainer extends StatefulWidget {
  final String videoUri;
  final int videoViewIndex;

  // Metadata fields
  final String? title;
  final String? author;
  final String? category;
  final int? likes;
  final int? comments;
  final int? views;

  const VideoPlayerContainer({
    Key? key,
    required this.videoUri,
    required this.videoViewIndex,
    this.title,
    this.author,
    this.category,
    this.likes,
    this.comments,
    this.views,
  }) : super(key: key);

  @override
  State<VideoPlayerContainer> createState() => _VideoPlayerContainerState();
}

class _VideoPlayerContainerState extends State<VideoPlayerContainer>
    with AutomaticKeepAliveClientMixin {
  late final BetterPlayerController _controller;
  String? _targetVideo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        aspectRatio: 9 / 16,
        autoPlay: true,
        looping: true,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableFullscreen: true,
          enablePlayPause: true,
        ),
      ),
    );
    _loadVideo();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    try {
      final uri = Uri.parse("https://${widget.videoUri}");
      final response = await http.get(uri);
      if (!mounted || response.statusCode != 200) return;

      final data = json.decode(response.body);
      final playlistUrl = data['streamingPlaylists']?.isNotEmpty
          ? data['streamingPlaylists'][0]['playlistUrl']
          : null;

      if (playlistUrl != null) {
        _targetVideo = playlistUrl;
        _controller.setupDataSource(
          BetterPlayerDataSource.network(
            _targetVideo!,
            videoFormat: BetterPlayerVideoFormat.hls,
            headers: const {"User-Agent": "Flutter"},
          ),
        );
        _controller.addEventsListener((event) {
          if (event.betterPlayerEventType ==
                  BetterPlayerEventType.initialized &&
              mounted) {
            setState(() => _isLoading = false);
          }
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print('Error loading video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : BetterPlayer(controller: _controller)
        ),
        if (!_isLoading)
          _buildOverlay(
            title: widget.title ?? "Untitled",
            author: widget.author ?? "PeerTube",
            category: widget.category ?? "Unknown",
            likes: widget.likes ?? 0,
            comments: widget.comments ?? 0,
            views: widget.views ?? 0,
          ),
      ],
    );
  }

  Widget _buildOverlay({
    required String title,
    required String author,
    required String category,
    required int likes,
    required int comments,
    required int views,
  }) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'by $author • $category',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _metric(Icons.thumb_up, likes),
                const SizedBox(width: 16),
                _metric(Icons.comment, comments),
                const SizedBox(width: 16),
                _metric(Icons.remove_red_eye, views),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(IconData icon, int value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          value.toString(),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
