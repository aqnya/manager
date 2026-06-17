import 'package:flutter/material.dart';
import 'package:nekosu/card_group.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.medium(title: Text('Settings')),
          SliverToBoxAdapter(
            child: CardGroup(
              children: [
                ListRow(
                  icon: const Icon(Icons.palette_outlined),
                  headline: const Text('外观'),
                  supporting: const Text('跟随系统'),
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
