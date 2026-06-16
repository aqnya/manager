import 'package:flutter/material.dart';
import 'package:nekosu/card_group.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: CardGroup(
        children: [
          ListRow(
            icon: const Icon(Icons.dark_mode_outlined),
            headline: const Text('外观'),
            supporting: const Text('跟随系统'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
