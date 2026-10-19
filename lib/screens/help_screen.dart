import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Как это работает')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section(context, 'Маршрут проектирования', [
              _step(context, '1', 'Размеры дома', 'Задайте габариты, угол крыши, этажность и шаг стоек.'),
              _step(context, '2', 'Каркас и материалы', 'Выберите сечения пиломатериалов, проёмы, утепление и обшивку.'),
              _step(context, '3', 'Смета', 'Отредактируйте цены, сохраните проект или выгрузите в PDF/Excel.'),
            ]),
            const SizedBox(height: 24),
            _section(context, 'Управление в 3D', [
              _gesture(context, Icons.touch_app_outlined, '1 палец', 'Вращает модель вокруг своей оси.'),
              _gesture(context, Icons.pinch_outlined, '2 пальца', 'Масштабирование и сдвиг модели.'),
              _gesture(context, Icons.touch_app_outlined, 'Двойной тап', 'Сброс камеры в исходное положение.'),
            ]),
            const SizedBox(height: 24),
            _section(context, 'Нормативы (СП 332)', [
              _text(context, 'Приложение учитывает требования СП 332.1325800.2017. Для домов без свесов (Барнхаус, Хай-тек) карнизный свес не рассчитывается. Учитывается высота цоколя и фактическое сечение сухой строганой доски.'),
            ]),
            const SizedBox(height: 40),
            Center(child: Text('KARKAS v1.3.5 · Офлайн', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _step(BuildContext context, String n, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 14, backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15), child: Text(n, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(body, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _gesture(BuildContext context, IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(body, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          )),
        ],
      ),
    );
  }

  Widget _text(BuildContext context, String text) {
    return Text(text, style: TextStyle(fontSize: 14, height: 1.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)));
  }
}
