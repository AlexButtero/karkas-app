import 'package:flutter/material.dart';
import '../models/house_style.dart';
import 'dimensions_screen.dart';

class StyleGuideScreen extends StatelessWidget {
  const StyleGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Типажи домов')),
      body: SafeArea(
        top: false,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: kHouseStyles.length,
          itemBuilder: (_, i) {
            final style = kHouseStyles[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _showStyle(context, style),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImage(style.imagePath, 180),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(style.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(style.tagline, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImage(String path, double height) {
    return Image.asset(
      path,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        String pngPath = path;
        if (path.endsWith('.jpg')) {
          pngPath = path.replaceAll('.jpg', '.png');
        }
        
        return Image.asset(
          pngPath,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: height, 
            color: Colors.grey, 
            child: const Center(child: Text('Нет фото', style: TextStyle(color: Colors.white))),
          ),
        );
      },
    );
  }

  void _showStyle(BuildContext context, HouseStyle style) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: EdgeInsets.zero,
          children: [
            Stack(
              children: [
                _buildImage(style.imagePath, 220),
                Positioned(
                  top: 16, right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(style.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(style.description, style: const TextStyle(fontSize: 14, height: 1.4)),
                  const SizedBox(height: 20),
                  Text('Особенности', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), letterSpacing: 1.1)),
                  const SizedBox(height: 8),
                  for (final tip in style.tips)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.circle, size: 6, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(child: Text(tip, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text('Рекомендуемые параметры', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), letterSpacing: 1.1)),
                  const SizedBox(height: 8),
                  Text('Габариты: ${style.lengthM.toInt()} × ${style.widthM.toInt()} м'),
                  if (!style.isAFrame) Text('Высота стен: ${style.wallHeightM} м'),
                  Text('Угол крыши: ${style.roofPitchDeg.toInt()}°'),
                  Text('Утепление: ${style.insulationMm.toInt()} мм'),
                  if (style.hasStonePlinth) Text('Цоколь: Каменный (${(style.groundClearanceM * 100).toInt()} см)', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  if (style.eaveOverhangM > 0) Text('Свес крыши: ${(style.eaveOverhangM * 100).toInt()} см') else const Text('Свес крыши: отсутствует'),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52, width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DimensionsScreen(style: style, initialDimensions: style.dimensions),
                        ));
                      },
                      child: const Text('Создать проект в этом стиле'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
