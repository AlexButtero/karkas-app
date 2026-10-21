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

  // Настройки Fusion 360
  RenderMode _renderMode = RenderMode.shadedWithEdges;
  double _sectionRatio = 1.0;

  @override
  void initState() {
    super.initState();
    _showRoof = widget.initialShowRoof;
    _showWalls = widget.initialShowWalls;
    _showFloors = widget.initialShowFloors;
    _showGrillage = widget.initialShowGrillage;
    if (widget.dimensions.isAFrame) _pitch = 0.85;
  }

  void _resetView() => setState(() {
        _rotation = -0.6;
        _pitch = widget.dimensions.isAFrame ? 0.85 : 0.55;
        _zoom = 1.0;
        _pan = Offset.zero;
      });

  // Snap Views
  void _setIsoView() => setState(() { _rotation = -0.6; _pitch = 0.55; });
  void _setFrontView() => setState(() { _rotation = 0.0; _pitch = 0.0; });
  void _setTopView() => setState(() { _rotation = 0.0; _pitch = 1.4; });
  void _setSideView() => setState(() { _rotation = -1.57; _pitch = 0.0; });

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
          // Кнопки стандартных видов (Snap Views)
          IconButton(icon: const Icon(Icons.view_in_ar), tooltip: 'Изометрия', onPressed: _setIsoView),
          IconButton(icon: const Icon(Icons.crop_portrait), tooltip: 'Спереди', onPressed: _setFrontView),
          IconButton(icon: const Icon(Icons.crop_square), tooltip: 'Сверху', onPressed: _setTopView),
          IconButton(icon: const Icon(Icons.vertical_split), tooltip: 'Сбоку', onPressed: _setSideView),
          IconButton(icon: const Icon(Icons.layers_outlined), tooltip: 'Слои', onPressed: _showLayersMenu),
          IconButton(icon: const Icon(Icons.restart_alt), tooltip: 'Сброс', onPressed: _resetView),
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
                    _zoom = (_startZoom * d.scale).clamp(0.2, 25.0);
                    if (d.pointerCount == 1) {
                      _rotation -= d.focalPointDelta.dx * 0.01;
                      _pitch = (_pitch + d.focalPointDelta.dy * 0.01).clamp(0.0, 1.5);
                    } else if (d.pointerCount >= 2) {
                      _pan += d.focalPointDelta;
                    }
                  });
                },
                onDoubleTap: _resetView,
                child: ClipRect(
                  child: CustomPaint(
                    painter: FramePainter(
                      dim: widget.dimensions,
                      params: widget.params,
                      rotation: _rotation, pitch: _pitch, zoom: _zoom, pan: _pan,
                      showRoof: _showRoof, showWalls: _showWalls, showFloors: _showFloors, showGrillage: _showGrillage,
                      renderMode: _renderMode,
                      sectionRatio: _sectionRatio,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            
            // ПАНЕЛЬ ИНСТРУМЕНТОВ (Fusion 360 Style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
              child: Column(
                children: [
                  // Режимы отображения
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildModeButton(Icons.layers, 'С затенением', RenderMode.shaded),
                      _buildModeButton(Icons.grid_on, 'С ребрами', RenderMode.shadedWithEdges),
                      _buildModeButton(Icons.grid_4x4, 'Каркас', RenderMode.wireframe),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Разрез
                  Row(
                    children: [
                      const Icon(Icons.content_cut, size: 18, color: Colors.white54),
                      const SizedBox(width: 8),
                      const Text('Разрез', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      Expanded(
                        child: Slider(
                          value: _sectionRatio,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (v) => setState(() => _sectionRatio = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(IconData icon, String tooltip, RenderMode mode) {
    final isSelected = _renderMode == mode;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _renderMode = mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent),
          ),
          child: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white54, size: 20),
        ),
      ),
    );
  }
}
