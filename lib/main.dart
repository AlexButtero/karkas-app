import 'package:flutter/material.dart';
import 'core/theme_controller.dart';
import 'screens/onboarding_screen.dart';
import 'screens/projects_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KarkasApp());
}

class KarkasApp extends StatelessWidget {
  const KarkasApp({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF3B30);

    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (_, __) => MaterialApp(
        title: 'KARKAS',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeController.instance.mode,
        // СВЕТЛАЯ ТЕМА
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: const ColorScheme.light(primary: accent, surface: Colors.white, onSurface: Colors.black87),
          scaffoldBackgroundColor: const Color(0xFFF2F2F5),
          appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.black87),
          dividerColor: Colors.black12,
          filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
          inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: accent, width: 1.5))),
          segmentedButtonTheme: SegmentedButtonThemeData(style: SegmentedButton.styleFrom(selectedBackgroundColor: accent.withValues(alpha: 0.1), selectedForegroundColor: accent)),
        ),
        // ТЕМНАЯ ТЕМА
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(primary: accent, surface: Color(0xFF151515), onSurface: Colors.white),
          scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
          dividerColor: Colors.white12,
          filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white, minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
          inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF151515), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: accent, width: 1.5))),
          segmentedButtonTheme: SegmentedButtonThemeData(style: SegmentedButton.styleFrom(selectedBackgroundColor: accent.withValues(alpha: 0.2), selectedForegroundColor: accent)),
        ),
        home: const _Bootstrap(),
      ),
    );
  }
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  bool _loaded = false;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await ThemeController.instance.load();
      final show = await OnboardingScreen.shouldShow();
      if (mounted) {
        setState(() {
          _showOnboarding = show;
          _loaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loaded = true;
          _showOnboarding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _showOnboarding ? const OnboardingScreen() : const ProjectsScreen();
  }
}
