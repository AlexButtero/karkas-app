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
        _rotation = -0.6; _pitch = widget.dimensions.isAFrame ? 0.85 : 0.55;
        _zoom = 1.0; _pan = Offset.zero;
      });

  void _setView(String view) {
    setState(() {
      switch (view) {
        case 'iso': _rotation = -0.6; _pitch = 0.55; break;
        case 'front': _rotation = 0.0; _pitch = 0.0; break;
        case 'top': _rotation = 0.0; _pitch = 1.5; break;
        case 'side': _rotation = -1.57; _pitch = 0.0; break;
      }
    });
  }

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

  void _showSectionPanel() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Разрез конструкции', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.content_cut, size: 20, color: Colors.white54),
                  Expanded(
                    child: Slider(
                      value: _sectionRatio,
                      min: 0.0, max: 1.0,
                      onChanged: (v) { setState(() => _sectionRatio = v); setModalState(() {}); },
                    ),
                  ),
                  Text('${(_sectionRatio * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              TextButton.icon(
                onPressed: () { setState(() => _sectionRatio = 1.0); Navigator.pop(ctx); },
                icon: const Icon(Icons.fullscreen),
                label: const Text('Убрать разрез'),
              )
            ],
          ),
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
          PopupMenuButton<String>(
            tooltip: 'Виды',
            icon: const Icon(Icons.videocam_outlined),
            onSelected: _setView,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'iso', child: Text('Изометрия')),
              PopupMenuItem(value: 'front', child: Text('Спереди')),
              PopupMenuItem(value: 'side', child: Text('Сбоку')),
              PopupMenuItem(value: 'top', child: Text('Сверху')),
            ],
          ),
          IconButton(icon: const Icon(Icons.content_cut), tooltip: 'Разрез', onPressed: _showSectionPanel),
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
                      renderMode: _renderMode, sectionRatio: _sectionRatio,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModeButton(Icons.circle, 'С затенением', RenderMode.shaded),
                  _buildModeButton(Icons.grid_3x3, 'С ребрами', RenderMode.shadedWithEdges),
                  _buildModeButton(Icons.grid_4x4, 'Каркас', RenderMode.wireframe),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => setState(() => _renderMode = mode),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent),
            ),
            child: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white54, size: 24),
          ),
        ),
      ),
    );
  }
}
