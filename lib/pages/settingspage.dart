import 'package:flutter/material.dart';
import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool autoPlayMedia = false;
  bool showBoosts = true;
  bool enableNotifications = true;
  bool useDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          /// ───────────────────────────
          /// ACCOUNT HEADER
          /// ───────────────────────────
          BigUserCard(
            backgroundColor: Colors.blue.shade600,
            userName: '@user@example.social',
            userProfilePic: const AssetImage('assets/avatar.png'),
            cardActionWidget: SettingsItem(
              icons: Icons.edit,
              title: "Edit",
              onTap: () {
                // Edit account
              },
            ),
          ),

          const SizedBox(height: 20),

          /// ───────────────────────────
          /// ACCOUNT / INSTANCE
          /// ───────────────────────────
          SettingsGroup(
            settingsGroupTitle: 'Account',
            items: [
              SettingsItem(
                title: 'Instance',
                subtitle: 'example.social',
                icons: Icons.public,
                onTap: () {
                  // Show instance info
                },
              ),
              SettingsItem(
                title: 'Log out',
                icons: Icons.logout,
                titleStyle: const TextStyle(color: Colors.red),
                onTap: () {
                  // Logout logic
                },
              ),
            ],
          ),

          /// ───────────────────────────
          /// TIMELINE & CONTENT
          /// ───────────────────────────
          SettingsGroup(
            settingsGroupTitle: 'Timeline & Content',
            items: [
              SettingsItem(
                title: 'Show boosts',
                subtitle: 'Include reblogs in timelines',
                icons: Icons.repeat,
                trailing: Switch(
                  value: showBoosts,
                  onChanged: (value) {
                    setState(() => showBoosts = value);
                  },
                ),
              ),
              SettingsItem(
                title: 'Autoplay media',
                subtitle: 'GIFs and videos',
                icons: Icons.play_arrow,
                trailing: Switch(
                  value: autoPlayMedia,
                  onChanged: (value) {
                    setState(() => autoPlayMedia = value);
                  },
                ),
              ),
            ],
          ),

          /// ───────────────────────────
          /// NOTIFICATIONS
          /// ───────────────────────────
          SettingsGroup(
            settingsGroupTitle: 'Notifications',
            items: [
              SettingsItem(
                title: 'Enable notifications',
                icons: Icons.notifications,
                trailing: Switch(
                  value: enableNotifications,
                  onChanged: (value) {
                    setState(() => enableNotifications = value);
                  },
                ),
              ),
              SettingsItem(
                title: 'Notification preferences',
                icons: Icons.tune,
                onTap: () {
                  // Open notification settings
                },
              ),
            ],
          ),

          /// ───────────────────────────
          /// PRIVACY & SAFETY
          /// ───────────────────────────
          SettingsGroup(
            settingsGroupTitle: 'Privacy & Safety',
            items: [
              SettingsItem(
                title: 'Muted accounts',
                icons: Icons.volume_off,
                onTap: () {},
              ),
              SettingsItem(
                title: 'Blocked accounts',
                icons: Icons.block,
                onTap: () {},
              ),
              SettingsItem(
                title: 'Content filters',
                icons: Icons.filter_alt,
                onTap: () {},
              ),
            ],
          ),

          /// ───────────────────────────
          /// APPEARANCE
          /// ───────────────────────────
          SettingsGroup(
            settingsGroupTitle: 'Appearance',
            items: [
              SettingsItem(
                title: 'Dark mode',
                icons: Icons.dark_mode,
                trailing: Switch(
                  value: useDarkMode,
                  onChanged: (value) {
                    setState(() => useDarkMode = value);
                  },
                ),
              ),
            ],
          ),

          /// ───────────────────────────
          /// ABOUT
          /// ───────────────────────────
          SettingsGroup(
            settingsGroupTitle: 'About',
            items: [
              SettingsItem(
                title: 'About this app',
                icons: Icons.info,
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'ActivityPub Client',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2026',
                  );
                },
              ),
              SettingsItem(
                title: 'Open source licenses',
                icons: Icons.article,
                onTap: () {
                  showLicensePage(context: context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
