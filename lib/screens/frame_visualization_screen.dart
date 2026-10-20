import 'package:flutter/material.dart';
import '../models/house_dimensions.dart';
import '../models/frame_params.dart';
import '../painter/frame_painter.dart';

class FrameVisualizationScreen extends StatefulWidget {
  final HouseDimensions dimensions;
  final FrameParams params;
  final bool initialShowRoof;
  final bool initialShowWalls;
  final bool initialShowFloors;
  final bool initialShowGrillage;

  const FrameVisualizationScreen({
    required this.dimensions,
    required this.params,
    this.initialShowRoof = true,
    this.initialShowWalls = true,
    this.initialShowFloors = true,
    this.initialShowGrillage = true,
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
  
  late bool _showRoof;
  late bool _showWalls;
  late bool _showFloors;
  late bool _showGrillage;

  @override
  void initState() {
    super.initState();
    _showRoof = widget.initialShowRoof;
    _showWalls = widget.initialShowWalls;
    _showFloors = widget.initialShowFloors;
    _showGrillage = widget.initialShowGrillage;
    if (widget.dimensions.isAFrame) _pitch = 0.85;
  }

  void _reset() => setState(() {
        _rotation = -0.6;
        _pitch = widget.dimensions.isAFrame ? 0.85 : 0.55;
        _zoom = 1.0;
        _pan = Offset.zero;
      });

  void _showLayersMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('Видимость элементов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            SwitchListTile(title: const Text('Ростверк (низ)'), value: _showGrillage, onChanged: (v) { setState(() => _showGrillage = v); setModalState(() {}); }),
            SwitchListTile(title: const Text('Полы и перекрытия'), value: _showFloors, onChanged: (v) { setState(() => _showFloors = v); setModalState(() {}); }),
            SwitchListTile(title: const Text('Стены каркаса'), value: _showWalls, onChanged: (v) { setState(() => _showWalls = v); setModalState(() {}); }),
            SwitchListTile(title: const Text('Крыша (стропила)'), value: _showRoof, onChanged: (v) { setState(() => _showRoof = v); setModalState(() {}); }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Каркас'),
        actions: [
          IconButton(icon: const Icon(Icons.layers_outlined), tooltip: 'Слои', onPressed: _showLayersMenu),
          IconButton(icon: const Icon(Icons.restart_alt), tooltip: 'Сброс', onPressed: _reset),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onScaleStart: (d) { _lastFocal = d.focalPoint; _startZoom = _zoom; },
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
                      rotation: _rotation, pitch: _pitch, zoom: _zoom, pan: _pan,
                      showRoof: _showRoof, showWalls: _showWalls, showFloors: _showFloors, showGrillage: _showGrillage,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
              child: Text('1 палец — вращение · 2 пальца — масштаб · Иконка слоев (сверху) — скрыть элементы', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
            ),
          ],
        ),
      ),
    );
  }
}
