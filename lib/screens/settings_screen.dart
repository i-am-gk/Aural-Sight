import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/tts_service.dart';
import '../utils/app_localization.dart';

import 'user_profile_screen.dart';
import 'terms_screen.dart';
import 'legal_screen.dart';
import 'about_screen.dart';
import 'premium_info_screen.dart';

class SettingsScreen extends StatelessWidget {
  final bool fromVoice;
  const SettingsScreen({super.key, this.fromVoice = false});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final provider = Provider.of<LanguageProvider>(context);
    final tts = TtsService();

    final List<_SettingsItem> items = [
      _SettingsItem(
        icon: Icons.person,
        title: AppLocalizations.t(context, 'settings_user_profile'),
        subtitle: AppLocalizations.t(context, 'settings_user_profile_sub'),
        screen: const UserProfileScreen(),
      ),
      _SettingsItem(
        icon: Icons.description,
        title: AppLocalizations.t(context, 'settings_terms'),
        subtitle: AppLocalizations.t(context, 'settings_terms_sub'),
        screen: const TermsScreen(),
      ),
      _SettingsItem(
        icon: Icons.gavel,
        title: AppLocalizations.t(context, 'settings_legal'),
        subtitle: AppLocalizations.t(context, 'settings_legal_sub'),
        screen: const LegalScreen(),
      ),
      _SettingsItem(
        icon: Icons.info,
        title: AppLocalizations.t(context, 'settings_about'),
        subtitle: AppLocalizations.t(context, 'settings_about_sub'),
        screen: AboutScreen(),
      ),
      _SettingsItem(
        icon: Icons.workspace_premium,
        title: AppLocalizations.t(context, 'future_premium'),
        subtitle: AppLocalizations.t(context, 'future_premium_sub'),
        screen: PremiumInfoScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.t(context, 'settings')),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Icon(item.icon, color: Colors.teal, size: 30),
              title: Text(
                item.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(item.subtitle),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey),
              onTap: () {
                tts.speak(item.title);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item.screen),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.screen,
  });
}
