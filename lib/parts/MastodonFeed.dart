import 'dart:math';
import 'package:flutter/material.dart';
import 'package:toot_ui/toot_ui.dart';
import 'package:toot_ui/models/api/v1/mastodonuser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MastodonFeed extends ConsumerStatefulWidget {
  const MastodonFeed({Key? key}) : super(key: key);

  @override
  _MastodonFeedState createState() => _MastodonFeedState();
}

class _MastodonFeedState extends ConsumerState<MastodonFeed> {
  double entropy = 0.5;
  List<Widget> feedItems = [];
  String hoveringLayer = "Default";

  final ScrollController _scrollController = ScrollController();
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    // Load initial posts
    for (int i = 0; i < 5; i++) {
      loadNewPost();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (mounted) loadNewPost();
    }
  }

  void loadNewPost() {
    if (!mounted) return;

    setState(() {
      entropy = 0.5 + _random.nextDouble();

      // Generate a dummy MastodonStatus using your real model
      final status = MastodonStatus(
        id: _random.nextInt(1000000).toString(),
        content: _dummyContent(),
        account: MastodonUser(
          id: _random.nextInt(10000).toString(),
          displayName: 'User${_random.nextInt(100)}',
          username: 'user${_random.nextInt(100)}',
          verified: _random.nextBool(),
          avatarUrl:
              'https://i.pravatar.cc/${152 * _random.nextInt(70)}',
          url: 'https://example.com/user${_random.nextInt(100)}',
        ),
        url: 'https://example.com/status/${_random.nextInt(100000)}',
        createdAt: DateFormat('yyyy-MM-dd – kk:mm')
            .format(DateTime.now().subtract(Duration(minutes: _random.nextInt(60)))),
        mediaUrls: _random.nextBool()
            ? ['https://picsum.photos/400/200?random=${_random.nextInt(1000)}']
            : [],
        reblogsCount: _random.nextInt(50),
        repliesCount: _random.nextInt(20),
        favouritesCount: _random.nextInt(100),
        reblogged: _random.nextBool(),
        favourited: _random.nextBool(),
        bookmarked: _random.nextBool(),
      );

      feedItems.add(TootView(
        status,
        darkMode: false,
      ));
    });
  }

  String _dummyContent() {
    final contents = [
      "Hello Mastodon! 🌟",
      "Enjoying some code and coffee ☕",
      "Check out this cool photo! 📷",
      "Random thoughts of the day...",
      "Learning Flutter is fun! 🚀",
      "Here's a little joke: Why did the chicken cross the road?",
    ];
    return contents[_random.nextInt(contents.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: feedItems.length,
                itemBuilder: (context, index) => feedItems[index],
              ),
            ),
          ],
        ),
        _buildHoveringButtons(context),
      ],
    );
  }

  Widget _buildHoveringButtons(BuildContext context) {
    switch (hoveringLayer) {
      case "Sort/Filter":
        return Positioned(
          top: 32,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.article), onPressed: () {}),
              IconButton(icon: const Icon(Icons.people), onPressed: () {}),
              IconButton(icon: const Icon(Icons.emoji_emotions), onPressed: () {}),
              IconButton(icon: const Icon(Icons.trending_up), onPressed: () {}),
              IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () => setState(() => hoveringLayer = "Default")),
            ],
          ),
        );
      case "CreatePicker":
        return Stack(
            fit: StackFit.loose,
            alignment: Alignment.center,
            children: [
              Container(
                color: Colors.black45,
                width: double.infinity,
                height: double.infinity,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const StatusForm(),
                  IconButton(icon: const Icon(Icons.photo), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.text_fields), onPressed: () {}),
                  IconButton(
                      icon: const Icon(Icons.cancel),
                      iconSize: 64,
                      onPressed: () => setState(() => hoveringLayer = "Default")),
                ]
              ),
            ],
          );
      default:
        return Positioned(
          top: 32,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  icon: const Icon(Icons.create),
                  onPressed: () => setState(() => hoveringLayer = "CreatePicker")),
              IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => setState(() => hoveringLayer = "Sort/Filter")),
            ],
          ),
        );
    }
  }
}
