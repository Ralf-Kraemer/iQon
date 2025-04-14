import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:icp/pages/homepage.dart';

import '../state/objects/ApiOAuth.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool showLoginFields = false;
  bool error = false;
  String url = 'https://fosstodon.org';
  ApiOAuth api = ApiOAuth();

  @override
  void initState() {
    super.initState();
    handleInitialDeepLink(); // Look for code on startup
    checkLoginStatus();
  }

  void handleInitialDeepLink() async {
    final uri = Uri.base; // e.g., ICP://ralfkraemer.eu?code=abc123
    if (uri.scheme == 'icp' && uri.queryParameters.containsKey('code')) {
      final code = uri.queryParameters['code'];
      if (code != null) {
        await api.exchangeCodeForTokens(code);
        navigateToTimeline();
      }
    }
  }

  void checkLoginStatus() async {
    var access_token = await api.maybeRefreshAccessToken();
    print("Access token: $access_token");
    if (access_token == null) {
      setState(() {
        showLoginFields = true;
      });
    } else {
      navigateToTimeline();
    }
  }

  void prepareLogin(String? _url) async {
    try {
      await api.setBaseUrl(_url ?? url);
      await api.fetchClientIdSecret();
      var redirectUrl = await api.getRedirectUrl();
      openOAuthScreen(redirectUrl);
    } catch (e) {
      setState(() {
        error = true;
      });
    }
  }

  void openOAuthScreen(String url) {
    FlutterWebBrowser.openWebPage(
      url: url,
      customTabsOptions: CustomTabsOptions(
        shareState: CustomTabsShareState.on,
        instantAppsEnabled: true,
        showTitle: true,
        urlBarHidingEnabled: true,
      ),
      safariVCOptions: SafariViewControllerOptions(
        barCollapsingEnabled: true,
        dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
        modalPresentationCapturesStatusBarAppearance: true,
      ),
    );
  }

  void navigateToTimeline() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: showLoginFields
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LogoLoading(),
                  SizedBox(height: 48, child: Text("icp", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
                  TextButton(
                    onPressed: () => prepareLogin("https://icp.social"),
                    style: ButtonStyle(backgroundColor: WidgetStatePropertyAll<Color>(Colors.green)),
                    child: Text('🌼 icp.social', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () => prepareLogin("https://mastodon.social"),
                    style: ButtonStyle(backgroundColor: WidgetStatePropertyAll<Color>(Colors.deepPurple)),
                    child: Text('🦣 Mastodon.social', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                  SizedBox(height: 24, child: Text("OR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  DropdownMenu(
                    label: Text("OR pick entry point"),
                    dropdownMenuEntries: [
                      DropdownMenuEntry(value: "https://mas.to", label: "🦣 mas.to"),
                      DropdownMenuEntry(value: "https://fosstodon.org", label: "💻 Fosstodon"),
                      DropdownMenuEntry(value: "https://mstdn.social", label: "🐘 mstdn.social"),
                    ],
                    onSelected: (value) {
                      prepareLogin(value);
                    },
                  ),
                  SizedBox(height: 24, child: Text("OR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 50.0),
                    child: TextField(
                      onChanged: (value) => url = value,
                      textInputAction: TextInputAction.go,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        labelText: 'URL of ActivityPub instance',
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => prepareLogin(url),
                    child: Text('Connect'),
                  ),
                ],
              ),
            )
          : Center(child: LogoLoading()),
    );
  }
}

class LogoLoading extends StatelessWidget {
  const LogoLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff7c94b6),
        image: const DecorationImage(
          image: AssetImage('assets/images/logo-icp.png'),
          fit: BoxFit.fill,
        ),
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(75.0),
      ),
      height: 150.0,
      width: 150.0,
    );
  }
}
