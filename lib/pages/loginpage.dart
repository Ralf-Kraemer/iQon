import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:iqon/pages/homepage.dart';

import '../state/objects/ApiOAuth.dart';
import 'package:toot_ui/helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool showLoginFields = false;
  bool error = false;
  String url = 'https://fosstodon.org';
  final ApiOAuth api = ApiOAuth();
  final Helper helper = Helper.get();

  // Static dropdown entries for performance
  static const List<DropdownMenuEntry<String>> instanceEntries = [
    DropdownMenuEntry(value: "https://mastodon.social", label: "🦣#️⃣1️⃣ Mastodon.social"),
    DropdownMenuEntry(value: "https://mastodon.top", label: "🇫🇷🇬🇧🇪🇺 Mastodon.top"),
    DropdownMenuEntry(value: "https://kolektiva.social", label: "🏴☮️ Kolektiva.social"),
    DropdownMenuEntry(value: "https://union.place", label: "✊⛓️‍💥 union.place"),
    DropdownMenuEntry(value: "https://troet.cafe", label: "🇩🇪 Troet Café"),
    DropdownMenuEntry(value: "https://Mastodon.nl", label: "🇳🇱 Mastodon NL"),
    DropdownMenuEntry(value: "https://mastodontti.fi", label: "🇫🇮 Mastodontti FI"),
    DropdownMenuEntry(value: "https://mastodon.pt", label: "🇵🇹🇧🇷 Mastodon PT"),
    DropdownMenuEntry(value: "https://mastodon.uno", label: "🇮🇹 Mastodon.uno"),
    DropdownMenuEntry(value: "https://mastodon-belgium.be", label: "🇧🇪 Mastodon Belgium"),
    DropdownMenuEntry(value: "https://mastodon.nu", label: "🇸🇪 Mastodon.nu"),
    DropdownMenuEntry(value: "https://mastodonapp.uk", label: "🇬🇧 Mastodon App UK"),
    DropdownMenuEntry(value: "https://mastouille.fr", label: "🇫🇷 Mastouille.fr"),
    DropdownMenuEntry(value: "https://mstdn.ca", label: "🇨🇦 Mstdn.ca"),
    DropdownMenuEntry(value: "https://berlin.social", label: "🇩🇪🇪🇺 Berlin.social"),
    DropdownMenuEntry(value: "https://muenchen.social", label: "🇩🇪🇪🇺 Muenchen.social"),
    DropdownMenuEntry(value: "https://norden.social", label: "🇩🇪🇪🇺 Norden.social"),
    DropdownMenuEntry(value: "https://social.cologne", label: "🇩🇪🇪🇺 Social.Cologne"),
    DropdownMenuEntry(value: "https://bonn.social", label: "🇩🇪🇪🇺 Bonn.social"),
    DropdownMenuEntry(value: "https://hessen.social", label: "🇩🇪🇪🇺 Hessen.social"),
    DropdownMenuEntry(value: "https://fulda.social", label: "🇩🇪🇪🇺 Fulda.social"),
    DropdownMenuEntry(value: "https://muenster.im", label: "🇩🇪🇪🇺 Muenster.im"),
    DropdownMenuEntry(value: "https://rheinneckar.social", label: "🇩🇪🇪🇺 RheinNeckar.social"),
    DropdownMenuEntry(value: "https://dresden.network", label: "🇩🇪🇪🇺 Dresden.network"),
    DropdownMenuEntry(value: "https://leipzig.town", label: "🇩🇪🇪🇺 Leipzig.town"),
    DropdownMenuEntry(value: "https://aus.social", label: "🇦🇺🇳🇿 Aus.social (+Oceania)"),
    DropdownMenuEntry(value: "https://mastodon.com.tr", label: "🇹🇷 Mastodon Türkiye"),
    DropdownMenuEntry(value: "https://mastodon.scot", label: "🏴 Mastodon.scot"),
    DropdownMenuEntry(value: "https://sfba.social", label: "🇺🇸 SF Bay Area (+California)"),
    DropdownMenuEntry(value: "https://glasgow.social", label: "🏴 Glasgow.social"),
    DropdownMenuEntry(value: "https://mastodon.london", label: "🇬🇧 Mastodon.london"),
    DropdownMenuEntry(value: "https://mamot.fr", label: "🇫🇷 Ma mot FR"),
    DropdownMenuEntry(value: "https://piaille.fr", label: "🇫🇷 Piaille.fr"),
    DropdownMenuEntry(value: "https://tkz.one", label: "🇪🇸🇲🇽🇨🇴🇦🇷 TKZ.One"),
    DropdownMenuEntry(value: "https://fosstodon.org", label: "💻⚛️ FOSStodon"),
    DropdownMenuEntry(value: "https://mastodon.cloud", label: "🦣☁️ Mastodon.cloud"),
    DropdownMenuEntry(value: "https://mastodon.online", label: "🦣🛜 Mastodon.online"),
    DropdownMenuEntry(value: "https://mastodon.world", label: "🦣🌍 Mastodon.world"),
    DropdownMenuEntry(value: "https://mastodon.party", label: "🦣✨ Mastodon.party"),
    DropdownMenuEntry(value: "https://mastodon.lol", label: "🦣🏳️‍🌈 Mastodon.lol"),
    DropdownMenuEntry(value: "https://mas.to", label: "🦣 Mas.to"),
    DropdownMenuEntry(value: "https://disabled.social", label: "🦾 disabled.social"),
    DropdownMenuEntry(value: "https://pixelfed.social", label: "📸 Pixelfed"),
    DropdownMenuEntry(value: "https://octodon.social", label: "🏴‍☠️🏳️‍🌈 Octodon.social"),
    DropdownMenuEntry(value: "https://universeodon.com", label: "🛸 Universeodon.com"),
    DropdownMenuEntry(value: "https://social.tchncs.de", label: "🇩🇪⚙️ Tchncs"),
    DropdownMenuEntry(value: "https://bark.lgbt", label: "🐕🏳️‍🌈 Bark!"),
    DropdownMenuEntry(value: "https://mastodon.art", label: "🎨🖌️🎭 Mastodon.ART"),
    DropdownMenuEntry(value: "https://metalhead.club", label: "🎸🤘 Metalhead.club"),
    DropdownMenuEntry(value: "https://mastodon.radio", label: "📻🎤 Mastodon.Radio"),
    DropdownMenuEntry(value: "https://mstdn.games", label: "🕹️👾 mstdn.games"),
    DropdownMenuEntry(value: "https://mastodon.gamedev.place", label: "💻👾 GameDev Mastodon"),
    DropdownMenuEntry(value: "https://tech.lgbt", label: "🏳️‍🌈LGBTQIA+ in Tech"),
    DropdownMenuEntry(value: "https://infosec.exchange", label: "🛜🔓 Infosec Exchange"),
    DropdownMenuEntry(value: "https://newsie.social", label: "📰🖋️ Newsie.social (4th Estate)"),
    DropdownMenuEntry(value: "https://sciences.social", label: "🧪🧬 Sciences.social"),
    DropdownMenuEntry(value: "https://econtwitter.net", label: "🏦🐥 Econ Tw**ter"),
    DropdownMenuEntry(value: "https://poa.st", label: "💩🤡 Poast"),
    DropdownMenuEntry(value: "https://noc.social", label: "💻⚙️ Noc.social (Tech)"),
    DropdownMenuEntry(value: "https://mastodon.eus", label: "Mastodon Euskara (Basque)"),
    DropdownMenuEntry(value: "https://nafo.uk", label: "🇬🇧💕🇺🇦💕🇪🇺 NAFO.uk"),
  ];

  @override
  void initState() {
    super.initState();
    handleInitialDeepLink();
    checkLoginStatus();
  }

  void handleInitialDeepLink() async {
    final uri = Uri.base;
    if (uri.scheme == 'iqon' && uri.queryParameters.containsKey('code')) {
      final code = uri.queryParameters['code'];
      if (code != null) {
        try {
          await api.exchangeCodeForTokens(code);
          navigateToTimeline();
        } catch (e) {
          debugPrint('Error exchanging code from deep link: $e');
          setState(() => error = true);
        }
      }
    }
  }

  void checkLoginStatus() async {
    try {
      var accessToken = await api.maybeRefreshAccessToken();
      debugPrint("Access token: $accessToken");
      if (accessToken == null) {
        setState(() => showLoginFields = true);
      } else {
        navigateToTimeline();
      }
    } catch (e) {
      debugPrint("Error checking login status: $e");
      setState(() => showLoginFields = true);
    }
  }

  void prepareLogin(String? _url) async {
    try {
      await api.setBaseUrl(_url ?? url);
      await api.fetchClientIdSecret();
      final redirectUrl = await api.getRedirectUrl();
      openOAuthScreen(redirectUrl);
      helper.setHomeInstanceName(_url ?? url);
    } catch (e) {
      debugPrint('Login preparation error: $e');
      setState(() => error = true);
    }
  }

  void openOAuthScreen(String url) {
    FlutterWebBrowser.openWebPage(
      url: url,
      customTabsOptions: const CustomTabsOptions(
        shareState: CustomTabsShareState.on,
        instantAppsEnabled: true,
        showTitle: true,
        urlBarHidingEnabled: true,
      ),
      safariVCOptions: const SafariViewControllerOptions(
        barCollapsingEnabled: true,
        dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
        modalPresentationCapturesStatusBarAppearance: true,
      ),
    );
  }

  void navigateToTimeline() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (BuildContext context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final titleStyle = theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);
    final subtitleStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final buttonTextStyle = TextStyle(fontSize: 18, color: cs.onPrimary);

    return Scaffold(
      body: Center(
        child: showLoginFields
            ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const LogoLoading(),
                    const SizedBox(height: 16),
                    SizedBox(height: 48, child: Text("iQon", style: titleStyle)),
                    TextButton(
                      onPressed: () => prepareLogin("https://iqon.social"),
                      style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(cs.primary)),
                      child: Text(' Connect with iqon.social', style: buttonTextStyle),
                    ),
                    const SizedBox(height: 36),
                    Text("OR", style: subtitleStyle),
                    DropdownMenu(
                      textAlign: TextAlign.justify,
                      hintText: "Select instance",
                      dropdownMenuEntries: instanceEntries,
                      onSelected: prepareLogin,
                    ),
                    const SizedBox(height: 36),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 50.0),
                      child: TextField(
                        onChanged: (value) => url = value,
                        textInputAction: TextInputAction.go,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(hintText: 'Enter URL here'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton(onPressed: () => prepareLogin(url), child: const Text('Connect')),
                  ],
                ),
              )
            : const LogoLoading(),
      ),
    );
  }
}

class LogoLoading extends StatelessWidget {
  const LogoLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        image: const DecorationImage(
          image: AssetImage('assets/icon/icon.png'),
          fit: BoxFit.fill,
        ),
        border: Border.all(color: cs.onPrimaryContainer, width: 2),
        borderRadius: BorderRadius.circular(75),
      ),
    );
  }
}
