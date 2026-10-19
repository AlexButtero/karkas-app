import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'projects_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static Future<bool> shouldShow() async {
    final p = await SharedPreferences.getInstance();
    return !(p.getBool('onboarding_v1_done') ?? false);
  }

  static Future<void> markDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarding_v1_done', true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    (Icons.cabin_outlined, 'Проектируйте каркасный дом', 'Задайте габариты, выберите сечения — приложение рассчитает каркас и материалы.'),
    (Icons.auto_awesome_outlined, 'Начните с типажа', '5 популярных стилей — барнхаус, скандинавский, шале, A-Frame, хай-тек.'),
    (Icons.view_in_ar_outlined, 'Смотрите каркас в 3D', 'Объёмная изометрия дома с шагом стоек и стропилами.'),
    (Icons.picture_as_pdf_outlined, 'Смета за один тап', 'Цены редактируются, итог пересчитывается. Сохранение и экспорт в PDF/Excel.'),
  ];

  Future<void> _finish() async {
    await OnboardingScreen.markDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProjectsScreen()),
    );
  }

  void _next() {
    if (_page == _slides.length - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('KARKAS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 4, color: accent)),
                  TextButton(
                    onPressed: _finish,
                    child: Text('Пропустить', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF151515) : Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Icon(_slides[i].$1, size: 56, color: accent),
                      ),
                      const SizedBox(height: 36),
                      Text(_slides[i].$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      Text(_slides[i].$3, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8, height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? accent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: SizedBox(
                height: 54, width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_page == _slides.length - 1 ? 'Начать' : 'Далее', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
