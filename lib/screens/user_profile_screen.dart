import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_localization.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.t(context, 'user_profile_settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(AppLocalizations.t(context, 'language')),
          _card(
            child: ListTile(
              title: Text(AppLocalizations.t(context, 'ui_language')),
              subtitle: Text(provider.language == "en" ? "English" : "اردو"),
              trailing: DropdownButton<String>(
                value: provider.language,
                items: const [
                  DropdownMenuItem(value: "en", child: Text("English")),
                  DropdownMenuItem(value: "ur", child: Text("اردو")),
                ],
                onChanged: (v) {
                  if (v != null) provider.language = v;
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle("Accessibility"),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Font Size", style: TextStyle(fontSize: 16)),
                Slider(
                  min: 12,
                  max: 28,
                  divisions: 8,
                  value: provider.fontSize,
                  onChanged: (v) => provider.fontSize = v,
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle("Theme"),
          _card(
            child: ListTile(
              title: const Text("Theme"),
              trailing: DropdownButton<String>(
                value: provider.theme,
                items: const [
                  DropdownMenuItem(value: "teal", child: Text("Teal")),
                  DropdownMenuItem(value: "dark", child: Text("Dark")),
                  DropdownMenuItem(
                      value: "contrast", child: Text("High Contrast")),
                ],
                onChanged: (v) {
                  if (v != null) provider.theme = v;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      );

  Widget _card({required Widget child}) => Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      );
}
