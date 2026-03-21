import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alert_provider.dart';
import '../l10n/strings.dart';
import '../widgets/alert_banner.dart';
import '../widgets/alert_map.dart';

/// Root screen – adapts its layout for TV vs mobile.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 4 tabs: Status | Test | Map | Language
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertProvider>(
      builder: (context, provider, _) {
        final strings = AppStrings(provider.language);
        final isTV = provider.isTV;
        final alert = provider.currentAlert;

        return Directionality(
          textDirection: (provider.language == 'he' || provider.language == 'ar')
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: isTV
              ? _TVLayout(
                  provider: provider,
                  strings: strings,
                  tabController: _tabController,
                )
              : _MobileLayout(
                  provider: provider,
                  strings: strings,
                  tabController: _tabController,
                ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────
//  TV Layout
// ─────────────────────────────────────────

class _TVLayout extends StatelessWidget {
  final AlertProvider provider;
  final AppStrings strings;
  final TabController tabController;

  const _TVLayout({
    required this.provider,
    required this.strings,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final alert = provider.currentAlert;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Column(
        children: [
          // Top tab bar
          _TVTabBar(
            controller: tabController,
            strings: strings,
            hasAlert: alert != null,
          ),
          // Content
          Expanded(
            child: Stack(
              children: [
                TabBarView(
                  controller: tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatusTab(provider: provider, strings: strings, isTV: true),
                    _TestTab(provider: provider, strings: strings, isTV: true),
                    AlertMap(alert: alert, strings: strings),
                    _LanguageTab(provider: provider, strings: strings, isTV: true),
                  ],
                ),
                if (alert != null)
                  AlertBanner(
                    alert: alert,
                    strings: strings,
                    isTV: true,
                    onDismiss: () {
                      // The provider will clear once the API returns empty.
                      // For test alerts, it auto-clears after 20s.
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TVTabBar extends StatelessWidget {
  final TabController controller;
  final AppStrings strings;
  final bool hasAlert;

  const _TVTabBar({
    required this.controller,
    required this.strings,
    required this.hasAlert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: TabBar(
        controller: controller,
        labelStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 16),
        indicatorColor: hasAlert ? Colors.red : Colors.white,
        indicatorWeight: 3,
        tabs: [
          Tab(text: strings.statusTab),
          Tab(text: strings.testTab),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasAlert)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.location_on, color: Colors.red, size: 18),
                  ),
                Text(strings.mapTab),
              ],
            ),
          ),
          Tab(text: strings.langTab),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Mobile Layout
// ─────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final AlertProvider provider;
  final AppStrings strings;
  final TabController tabController;

  const _MobileLayout({
    required this.provider,
    required this.strings,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final alert = provider.currentAlert;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              strings.appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: tabController,
          indicatorColor: alert != null ? Colors.red : Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: strings.statusTab),
            Tab(text: strings.testTab),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (alert != null)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.location_on, color: Colors.red, size: 14),
                    ),
                  Text(strings.mapTab),
                ],
              ),
            ),
            Tab(text: strings.langTab),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: tabController,
            children: [
              _StatusTab(provider: provider, strings: strings, isTV: false),
              _TestTab(provider: provider, strings: strings, isTV: false),
              AlertMap(alert: alert, strings: strings),
              _LanguageTab(provider: provider, strings: strings, isTV: false),
            ],
          ),
          if (alert != null)
            AlertBanner(
              alert: alert,
              strings: strings,
              isTV: false,
              onDismiss: () {},
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Shared Tab Widgets
// ─────────────────────────────────────────

class _StatusTab extends StatelessWidget {
  final AlertProvider provider;
  final AppStrings strings;
  final bool isTV;

  const _StatusTab({
    required this.provider,
    required this.strings,
    required this.isTV,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = provider.isServiceRunning;
    final labelSize = isTV ? 20.0 : 15.0;
    final iconSize = isTV ? 40.0 : 28.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isRunning ? Icons.sensors : Icons.sensors_off,
            color: isRunning ? Colors.green : Colors.grey,
            size: iconSize * 1.8,
          ),
          const SizedBox(height: 24),
          Text(
            isRunning ? strings.serviceActive : strings.serviceInactive,
            style: TextStyle(
              color: isRunning ? Colors.greenAccent : Colors.white60,
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          _ServiceToggleButton(
            isRunning: isRunning,
            label: strings.enableAlerts,
            isTV: isTV,
            onToggle: () {
              if (isRunning) {
                provider.stopService();
              } else {
                provider.startService();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceToggleButton extends StatelessWidget {
  final bool isRunning;
  final String label;
  final bool isTV;
  final VoidCallback onToggle;

  const _ServiceToggleButton({
    required this.isRunning,
    required this.label,
    required this.isTV,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = isTV ? 60.0 : 48.0;
    final fontSize = isTV ? 18.0 : 15.0;

    return SizedBox(
      height: buttonHeight,
      child: ElevatedButton.icon(
        onPressed: onToggle,
        icon: Icon(isRunning ? Icons.stop_circle_outlined : Icons.play_circle_outline),
        label: Text(label, style: TextStyle(fontSize: fontSize)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isRunning ? Colors.red.shade800 : Colors.green.shade700,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: isTV ? 40 : 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _TestTab extends StatelessWidget {
  final AlertProvider provider;
  final AppStrings strings;
  final bool isTV;

  const _TestTab({
    required this.provider,
    required this.strings,
    required this.isTV,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = isTV ? 64.0 : 52.0;
    final fontSize = isTV ? 20.0 : 16.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            color: Colors.orange,
            size: isTV ? 72 : 52,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: buttonHeight,
            child: ElevatedButton.icon(
              onPressed: provider.triggerTestAlert,
              icon: Icon(Icons.play_arrow, size: isTV ? 28 : 20),
              label: Text(
                strings.runTest,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: isTV ? 48 : 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTab extends StatelessWidget {
  final AlertProvider provider;
  final AppStrings strings;
  final bool isTV;

  const _LanguageTab({
    required this.provider,
    required this.strings,
    required this.isTV,
  });

  static const _languages = [
    ('he', '🇮🇱', 'עברית'),
    ('en', '🇺🇸', 'English'),
    ('ru', '🇷🇺', 'Русский'),
    ('ar', '🇸🇦', 'العربية'),
  ];

  @override
  Widget build(BuildContext context) {
    final tileSize = isTV ? 80.0 : 60.0;
    final fontSize = isTV ? 20.0 : 16.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            strings.chooseLanguage,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isTV ? 22 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _languages.map((lang) {
              final isSelected = provider.language == lang.$1;
              return GestureDetector(
                onTap: () => provider.setLanguage(lang.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isTV ? 160 : 120,
                  height: tileSize,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.red.shade800
                        : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.red : Colors.white24,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(lang.$2,
                          style: TextStyle(fontSize: isTV ? 28 : 22)),
                      const SizedBox(height: 4),
                      Text(
                        lang.$3,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
