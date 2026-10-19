import 'package:flutter/material.dart';
import '../models/house_dimensions.dart';
import '../models/frame_params.dart';
import '../painter/frame_painter.dart';

class FrameVisualizationScreen extends StatefulWidget {
  final HouseDimensions dimensions;
  final FrameParams params;

  const FrameVisualizationScreen({
    required this.dimensions,
    required this.params,
    super.key,
  });

  @override
  State<FrameVisualizationScreen> createState() => _FrameVisualizationScreenState();
}

class _FrameVisualizationScreenState extends State<FrameVisualizationScreen> {
  double _rotation = -0.6;
  double _pitch = 0.55;
  double _zoom = 1.0;
  double _startZoom = 1.0;
  Offset _pan = Offset.zero;
  Offset _lastFocal = Offset.zero;
  bool _showRoof = true;

  void _reset() => setState(() {
        _rotation = -0.6;
        _pitch = 0.55;
        _zoom = 1.0;
        _pan = Offset.zero;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Каркас'),
        actions: [
          IconButton(
            tooltip: _showRoof ? 'Скрыть крышу' : 'Показать крышу',
            onPressed: () => setState(() => _showRoof = !_showRoof),
            icon: Icon(_showRoof ? Icons.roofing_outlined : Icons.roofing),
          ),
          IconButton(
            tooltip: 'Сбросить вид',
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onScaleStart: (d) {
                  _lastFocal = d.focalPoint;
                  _startZoom = _zoom;
                },
                onScaleUpdate: (d) {
                  setState(() {
                    if (d.pointerCount == 1) {
                      _rotation -= d.focalPointDelta.dx * 0.01;
                      _pitch = (_pitch + d.focalPointDelta.dy * 0.01).clamp(0.1, 1.4);
                    } else if (d.pointerCount >= 2) {
                      _zoom = (_startZoom * d.scale).clamp(0.2, 5.0);
                      _pan += d.focalPointDelta;
                    }
                  });
                },
                onDoubleTap: _reset,
                child: ClipRect(
                  child: CustomPaint(
                    painter: FramePainter(
                      dim: widget.dimensions,
                      params: widget.params,
                      rotation: _rotation,
                      pitch: _pitch,
                      zoom: _zoom,
                      pan: _pan,
                      showRoof: _showRoof,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('Кровля', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 20),
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFE2B896), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('Каркас', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Сечение: ${widget.params.studs.label} · Шаг: ${widget.dimensions.studSpacingMm.toInt()} мм',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1 палец — вращение · 2 пальца — масштаб и сдвиг · 2× тап — сброс',
                    style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
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
