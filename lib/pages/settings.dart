import 'package:flutter/material.dart';
import 'package:nekosu/card_group.dart';
import 'package:nekosu/ffi.dart';
import 'package:nekosu/l10n/app_localizations.dart';
import 'package:nekosu/layout_insets.dart';
import 'package:nekosu/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsController.instance,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final l10n = AppLocalizations.of(context)!;
        final settings = SettingsController.instance;
        final navBarClearance = floatingNavBarClearance(context);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(l10n.settingsLabel),
                backgroundColor: scheme.surfaceContainer,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(0, 12, 0, navBarClearance),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SettingsSection(
                      title: l10n.settingsGeneral,
                      children: [
                        _SettingsChoice<AppThemeMode>(
                          value: settings.themeMode,
                          choices: [
                            _SettingsChoiceValue(
                              AppThemeMode.system,
                              l10n.themeSystem,
                            ),
                            _SettingsChoiceValue(
                              AppThemeMode.light,
                              l10n.themeLight,
                            ),
                            _SettingsChoiceValue(
                              AppThemeMode.dark,
                              l10n.themeDark,
                            ),
                          ],
                          onChanged: settings.setThemeMode,
                          child: ListRow(
                            icon: const Icon(Icons.brightness_6_outlined),
                            headline: Text(l10n.themeTitle),
                            supporting: Text(_themeModeLabel(settings, l10n)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                        ),
                        _SettingsChoice<String>(
                          value: settings.language,
                          choices: [
                            _SettingsChoiceValue('system', l10n.languageSystem),
                            _SettingsChoiceValue('en', l10n.languageEnglish),
                            _SettingsChoiceValue('zh', l10n.languageChinese),
                          ],
                          onChanged: settings.setLanguage,
                          child: ListRow(
                            icon: const Icon(Icons.translate_rounded),
                            headline: Text(l10n.settingsLanguage),
                            supporting: Text(
                              _languageLabel(settings.language, l10n),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SettingsSection(
                      title: l10n.appearance,
                      children: [
                        _SettingsChoice<AppThemeAccent>(
                          value: settings.themeAccent,
                          choices: [
                            _SettingsChoiceValue(
                              AppThemeAccent.materialYou,
                              l10n.themeColorMaterialYou,
                            ),
                            _SettingsChoiceValue(
                              AppThemeAccent.catppuccinBlue,
                              l10n.themeColorBlue,
                            ),
                            _SettingsChoiceValue(
                              AppThemeAccent.catppuccinLavender,
                              l10n.themeColorLavender,
                            ),
                            _SettingsChoiceValue(
                              AppThemeAccent.catppuccinGreen,
                              l10n.themeColorGreen,
                            ),
                          ],
                          onChanged: settings.setThemeAccent,
                          child: ListRow(
                            icon: const Icon(Icons.palette_outlined),
                            headline: Text(l10n.settingsThemeColor),
                            supporting: Text(
                              _accentLabel(settings.themeAccent, l10n),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                        ),
                        ListRow(
                          icon: const Icon(Icons.phone_android_rounded),
                          headline: Text(l10n.settingsAmoled),
                          supporting: Text(l10n.settingsAmoledSummary),
                          trailing: Switch(
                            value: settings.amoled,
                            onChanged: settings.setAmoled,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SettingsSection(
                      title: l10n.settingsAbout,
                      children: [
                        ListRow(
                          icon: const Icon(Icons.info_outline_rounded),
                          headline: Text(l10n.about),
                          supporting: Text(l10n.settingsAboutDescription),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showAbout(context, l10n),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAbout(BuildContext context, AppLocalizations l10n) {
    final kernel = NcoreFfi.kernelVersion;
    final module = NcoreFfi.moduleVersion;
    showAboutDialog(
      context: context,
      applicationName: l10n.appTitle,
      applicationVersion: SettingsController.managerVersion,
      applicationIcon: const Icon(Icons.security_rounded, size: 40),
      children: [
        Text(l10n.settingsAboutDescription),
        const SizedBox(height: 16),
        SelectableText(
          '${l10n.managerVersion}: ${SettingsController.managerVersion}\n'
          '${l10n.kernelVersion}: ${kernel ?? l10n.unknownValue}\n'
          '${l10n.moduleVersion}: ${module ?? l10n.unknownValue}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.55),
        ),
      ],
    );
  }

  static String _themeModeLabel(
    SettingsController settings,
    AppLocalizations l10n,
  ) {
    return switch (settings.themeMode) {
      AppThemeMode.system => l10n.themeSystem,
      AppThemeMode.light => l10n.themeLight,
      AppThemeMode.dark => l10n.themeDark,
    };
  }

  static String _accentLabel(AppThemeAccent accent, AppLocalizations l10n) {
    return switch (accent) {
      AppThemeAccent.materialYou => l10n.themeColorMaterialYou,
      AppThemeAccent.catppuccinBlue => l10n.themeColorBlue,
      AppThemeAccent.catppuccinLavender => l10n.themeColorLavender,
      AppThemeAccent.catppuccinGreen => l10n.themeColorGreen,
    };
  }

  static String _languageLabel(String language, AppLocalizations l10n) {
    return switch (language) {
      'en' => l10n.languageEnglish,
      'zh' => l10n.languageChinese,
      _ => l10n.languageSystem,
    };
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: scheme.primary),
          ),
        ),
        CardGroup(children: children),
      ],
    );
  }
}

class _SettingsChoiceValue<T> {
  const _SettingsChoiceValue(this.value, this.label);

  final T value;
  final String label;
}

class _SettingsChoice<T> extends StatelessWidget {
  const _SettingsChoice({
    required this.value,
    required this.choices,
    required this.onChanged,
    required this.child,
  });

  final T value;
  final List<_SettingsChoiceValue<T>> choices;
  final ValueChanged<T> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final choice in choices)
          PopupMenuItem<T>(
            value: choice.value,
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: choice.value == value
                      ? Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: scheme.primary,
                        )
                      : null,
                ),
                Text(
                  choice.label,
                  style: TextStyle(
                    fontWeight: choice.value == value
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: child,
    );
  }
}
