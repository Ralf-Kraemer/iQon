import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'videoplayercontainer.dart';

class PeerTubeVideo {
  final String uri;
  final String title;
  final String author;
  final String? category;
  final int likes;
  final int comments;
  final int views;

  PeerTubeVideo({
    required this.uri,
    required this.title,
    required this.author,
    this.category,
    required this.likes,
    required this.comments,
    required this.views,
  });
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final List<Widget> watchQueue = [];
  final List<PeerTubeVideo> videoQueue = [];

  final Random rng = Random();
  int seed = Random().nextInt(99);
  int fetchOffset = 0; // ✅ FIX: real pagination offset

  @override
  void initState() {
    super.initState();
    _updateWatchQueue(0);
    _updateWatchQueue(0);
  }

  Future<List<PeerTubeVideo>> _fetchPeerTubeVideos(
      String instanceDomain, int start, String search) async {
    final uri = Uri.https(
      instanceDomain,
      "api/v1/search/videos",
      {
        'count': '9',
        'durationMax': '240',
        'start': start.toString(),
        'sort': (seed % 5 > 2) ? '-publishedAt' : '-views',
        'search': search,
        'languageOneOf': 'en,de',
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      final items = (data['data'] as List?) ?? [];

      return items.map((item) {
        final uuid = item['uuid'];
        if (uuid == null) return null;

        return PeerTubeVideo(
          uri: "$instanceDomain/api/v1/videos/$uuid",
          title: item['name'] ?? 'Untitled',
          author: item['account']?['displayName'] ?? 'PeerTube',
          category: item['category']?['label']?.toString(),
          likes: item['likes'] ?? 0,
          comments: item['commentCount'] ?? 0,
          views: item['viewCount'] ?? 0,
        );
      }).whereType<PeerTubeVideo>().toList();
    } catch (e) {
      debugPrint("Failed to fetch PeerTube videos: $e");
      return [];
    }
  }

  String _selectPeerTubeInstance() {
    const instances = [
      'tube.shanti.cafe',
      'makertube.net',
      'peertube.1312.media',
      'videovortex.tv',
      'tilvids.com',
      'video.infosec.exchange',
      'video.causa-arcana.com',
      'video.coales.co',
      'peertube.craftum.pl',
      'tube.fediverse.games',
      'videos.domainepublic.net',
      'video.rubdos.be',
      'peertube.tweb.tv',
      'peertube.existiert.ch',
      'video.liberta.vip',
      'fediverse.tv',
      'videos.trom.tf',
      'peertube2.cpy.re',
      'peertube3.cpy.re',
      'framatube.org',
      'tube.p2p.legal',
      'peertube.gaialabs.ch',
      'peertube.uno',
      'peertube.slat.org',
      'peertube.opencloud.lu',
      'tube.nx-pod.de',
      'video.hardlimit.com',
      'tube.graz.social',
      'p.eertu.be'
    ];
    return instances[rng.nextInt(instances.length)];
  }

  Future<void> _updateWatchQueue(int pageIndex) async {
    // ✅ FIX: fetch only when needed, advance offset
    if (videoQueue.length < 3) {
      final fetched = await _fetchPeerTubeVideos(
        _selectPeerTubeInstance(),
        fetchOffset,
        '',
      );
      fetchOffset += fetched.length;
      videoQueue.addAll(fetched);
    }

    if (videoQueue.isEmpty) return; // ✅ crash guard

    if (watchQueue.length >= 9) {
      watchQueue.removeAt(0); // ✅ safe now, replacement guaranteed
    }

    final selector = rng.nextInt(videoQueue.length);
    final video = videoQueue[selector];

    watchQueue.add(VideoPlayerContainer(
      videoUri: video.uri,
      videoViewIndex: pageIndex,
      title: video.title,
      author: video.author,
      category: video.category,
      likes: video.likes,
      comments: video.comments,
      views: video.views,
    ));

    videoQueue.removeAt(selector);

    if (mounted) {
      setState(() {
        seed = rng.nextInt(99);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return watchQueue.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : PageView.builder(
            scrollDirection: Axis.vertical,
            onPageChanged: _updateWatchQueue,
            itemCount: watchQueue.length,
            itemBuilder: (context, index) => watchQueue[index],
          );
  }
}
