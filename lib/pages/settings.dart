import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:nekosu/card_group.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(title: Text(l10n.settingsLabel)),
          SliverToBoxAdapter(
            child: CardGroup(
              children: [
                ListRow(
                  icon: const Icon(Icons.palette_outlined),
                  headline: Text(l10n.appearance),
                  supporting: Text(l10n.followSystem),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
