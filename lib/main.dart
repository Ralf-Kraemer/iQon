import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:app_links/app_links.dart';

import 'state/objects/ApiOAuth.dart';
import 'AppTheme.dart';
import 'pages/homepage.dart';
import 'pages/loginpage.dart';
import 'package:toot_ui/helper.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const ProviderScope(child: iQonApp()));
}

class iQonApp extends ConsumerStatefulWidget {
  const iQonApp({super.key});

  @override
  ConsumerState<iQonApp> createState() => _iQonAppState();
}

class _iQonAppState extends ConsumerState<iQonApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri?>? _linkSub;

  bool _isLoading = true;
  bool _userIsLoggedIn = false;
  bool _authInProgress = false; // prevents races

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  /// Single entry point for startup logic
  Future<void> _initializeApp() async {
    _listenForIncomingLinks();
    await _checkLoginStatusSafely();
  }

  /// Defensive login check
  Future<void> _checkLoginStatusSafely() async {
    try {
      final accessToken =
          await Helper.get().getPrefString('accessToken');

      if (accessToken == null) {
        _setAuthState(loggedIn: false);
        return;
      }

      final api = ApiOAuth();

      final isValid = await api.maybeRefreshAccessToken();

      _setAuthState(loggedIn: isValid == true);
    } catch (e, st) {
      debugPrint('Auth check failed: $e\n$st');
      _setAuthState(loggedIn: false);
    }
  }

  void _setAuthState({required bool loggedIn}) {
    if (!mounted) return;

    setState(() {
      _userIsLoggedIn = loggedIn;
      _isLoading = false;
    });
  }

  /// Extract OAuth code safely
  String? _extractCode(Uri uri) {
    return uri.queryParameters['code'];
  }

  /// Handles OAuth redirect
  Future<void> _handleOAuthRedirect(Uri? uri) async {
    if (uri == null || _authInProgress) return;

    final code = _extractCode(uri);
    if (code == null) return;

    _authInProgress = true;

    try {
      final api = ApiOAuth();
      await api.exchangeCodeForTokens(code);

      if (!mounted) return;

      setState(() {
        _userIsLoggedIn = true;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('Token exchange failed: $e\n$st');
    } finally {
      _authInProgress = false;

      try {
        await FlutterWebBrowser.close();
      } catch (_) {
        // non-fatal
      }
    }
  }

  /// Incoming deep link listener
  void _listenForIncomingLinks() {
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) {
        if (!mounted) return;
        _handleOAuthRedirect(uri);
      },
      onError: (err, st) {
        debugPrint('Deep link error: $err\n$st');
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
      return MaterialApp(
        title: 'iQon',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    } else {
      FlutterNativeSplash.remove();
    }

    return MaterialApp(
      title: 'iQon',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: _userIsLoggedIn ? const HomePage() : LoginPage(),
    );
  }
}
