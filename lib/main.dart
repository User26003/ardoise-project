import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/ardoise_provider.dart';
import 'screens/add_entry_sheet.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'utils/responsive.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  final storage = StorageService();
  await storage.init();
  final provider = ArdoiseProvider(storage);
  await provider.load();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ChangeNotifierProvider.value(value: provider, child: const ArdoiseApp()),
  );
}

class ArdoiseApp extends StatelessWidget {
  const ArdoiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ardoise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Empêche le texte système très agrandi de casser la mise en page
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final clamped = mq.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.3,
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: clamped),
          child: child!,
        );
      },
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ArdoiseProvider>();
    if (!p.onboardingDone) {
      return const SettingsScreen(onboarding: true);
    }

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(onOpenStats: () => setState(() => _tab = 1)),
          const StatsScreen(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _MicFab(
        onTap: () => showAddEntrySheet(context, startListening: true),
        onLongPress: () => showAddEntrySheet(context),
      ),
      bottomNavigationBar: _PillNavBar(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _MicFab extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _MicFab({required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final short = R.isShort(context);
    final size = short ? 62.0 : 74.0;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.headerGradient,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepOrange.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.mic_rounded,
              color: Colors.white,
              size: short ? 28 : 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _PillNavBar({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final short = R.isShort(context);
    final wide = R.isWide(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        wide ? (R.width(context) - 420) / 2 : 16,
        0,
        wide ? (R.width(context) - 420) / 2 : 16,
        (short ? 6 : 12) + bottomPad,
      ),
      child: Container(
        height: short ? 58 : 68,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.people_alt_rounded,
                label: 'Clients',
                selected: index == 0,
                onTap: () => onChanged(0),
              ),
            ),
            const SizedBox(width: 84),
            Expanded(
              child: _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Stats',
                selected: index == 1,
                onTap: () => onChanged(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.deepOrange : AppColors.inkSoft;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(34),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.orange.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
