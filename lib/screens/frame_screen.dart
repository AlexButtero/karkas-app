import 'package:flutter/material.dart';
import '../models/frame_params.dart';
import '../models/house_dimensions.dart';
import '../models/lumber_section.dart';
import '../models/material_estimate.dart';
import '../models/opening.dart';
import 'estimate_screen.dart';
import 'frame_visualization_screen.dart';
import 'opening_editor_sheet.dart';

class FrameScreen extends StatefulWidget {
  final HouseDimensions dimensions;
  final FrameParams? initialParams;
  final int? projectId;
  final String? projectName;
  final Map<String, double>? savedPrices;

  const FrameScreen({
    required this.dimensions,
    this.initialParams,
    this.projectId,
    this.projectName,
    this.savedPrices,
    super.key,
  });
  
  @override
  State<FrameScreen> createState() => _FrameScreenState();
}

class _FrameScreenState extends State<FrameScreen> with SingleTickerProviderStateMixin {
  late LumberMaterialType _lt;
  late LumberSection _studs, _plates, _joists, _rafters;
  late LumberSection _batten, _cBatten, _crossBatten;
  
  late int _wallSpacing, _floorSpacing, _roofSpacing;
  late int _wallInsSpacing, _roofInsSpacing;
  
  late List<Opening> _openings;
  late InsulationType _ins;
  late double _insT;
  late SheathingType _sheath;
  late BottomPlateType _bpType;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    final p = widget.initialParams ?? FrameParams();
    _lt = p.lumberType;
    _studs = p.studs; _plates = p.plates; _joists = p.joists; _rafters = p.rafters;
    _batten = p.batten; _cBatten = p.counterBatten; _crossBatten = p.crossBattens;
    
    _wallSpacing = p.wallStudSpacingMm;
    _floorSpacing = p.floorJoistSpacingMm;
    _roofSpacing = p.roofRafterSpacingMm;
    _wallInsSpacing = p.wallCrossInsulationSpacingMm;
    _roofInsSpacing = p.roofCrossInsulationSpacingMm;
    
    _ins = p.insulation; _insT = p.insulationThickness; _sheath = p.sheathing;
    _bpType = p.bottomPlateType;
    _openings = p.openings.isEmpty ? Opening.defaults() : List.of(p.openings);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  FrameParams _params() => FrameParams(
        lumberType: _lt, studs: _studs, plates: _plates, joists: _joists, rafters: _rafters,
        batten: _batten, counterBatten: _cBatten, crossBattens: _crossBatten,
        wallStudSpacingMm: _wallSpacing, floorJoistSpacingMm: _floorSpacing, roofRafterSpacingMm: _roofSpacing,
        wallCrossInsulationSpacingMm: _wallInsSpacing, roofCrossInsulationSpacingMm: _roofInsSpacing,
        openings: _openings, insulation: _ins, insulationThickness: _insT, sheathing: _sheath,
        bottomPlateType: _bpType,
      );

  MaterialEstimate _calc() => MaterialEstimate.fromDimensions(
        widget.dimensions,
        studs: _studs, plates: _plates, joists: _joists, rafters: _rafters,
        batten: _batten, counterBatten: _cBatten, crossBattens: _crossBatten,
        wallSpacingMm: _wallSpacing, floorSpacingMm: _floorSpacing, roofSpacingMm: _roofSpacing,
        wallInsSpacingMm: _wallInsSpacing, roofInsSpacingMm: _roofInsSpacing,
        openings: _openings, insulation: _ins, insulationThicknessMm: _insT,
        bottomPlateType: _bpType,
      );

  @override
  Widget build(BuildContext context) {
    final e = _calc();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каркас дома'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_in_ar_outlined),
            tooltip: 'Показать 3D',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => FrameVisualizationScreen(dimensions: widget.dimensions, params: _params()),
            )),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: '1. Ростверк'),
            Tab(text: '2. Полы'),
            Tab(text: '3. Стены'),
            Tab(text: '4. Перекрытия'),
            Tab(text: '5. Перегородки'),
            Tab(text: '6. Чердак'),
            Tab(text: '7. Крыша'),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildGrillageTab(),
            _buildFloorsTab(),
            _buildWallsTab(),
            _buildCeilingsTab(),
            _buildPartitionsTab(),
            _buildAtticTab(),
            _buildRoofTab(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => EstimateScreen(
                estimate: e, sheathing: _sheath, dimensions: widget.dimensions, frameParams: _params(),
                projectId: widget.projectId, projectName: widget.projectName, savedPrices: widget.savedPrices,
              ),
            )),
            child: const Text('Перейти к смете', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  // --- 1. РОСТВЕРК ---
  Widget _buildGrillageTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('Нижняя обвязка (Ростверк)', [
          SegmentedButton<BottomPlateType>(
            showSelectedIcon: false,
            segments: BottomPlateType.values.map((t) => ButtonSegment(value: t, label: Text(t.label))).toList(),
            selected: {_bpType},
            onSelectionChanged: (s) => setState(() => _bpType = s.first),
          ),
          if (_bpType != BottomPlateType.solid) ...[
            const SizedBox(height: 8),
            Text('Доски для пакета: ${_plates.displayLabel}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
          ],
        ]),
        _card('Центральные балки', [
          Text('Количество балок: ${widget.dimensions.centralBeamCount}', style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ],
    );
  }

  // --- 2. ПОЛЫ ---
  Widget _buildFloorsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('Лаги и Черновой пол', [
          _dd('Сечение лаг', sectionsFor(_lt), _joists, (v) => setState(() => _joists = v)),
          const SizedBox(height: 12),
          _spacingSelector('Шаг лаг', _floorSpacing, (v) => setState(() => _floorSpacing = v)),
        ]),
        _card('Перекрёстное утепление пола', [
          _dd('Сечение досок (поперёк)', battensFor(_lt), _crossBatten, (v) => setState(() => _crossBatten = v)),
          const SizedBox(height: 12),
          _spacingSelector('Шаг досок утепления', _wallInsSpacing, (v) => setState(() => _wallInsSpacing = v)),
        ]),
      ],
    );
  }

  // --- 3. СТЕНЫ ---
  Widget _buildWallsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('Стойки и обвязка', [
          _dd('Стойки', sectionsFor(_lt), _studs, (v) => setState(() => _studs = v)),
          _dd('Верхняя обвязка', sectionsFor(_lt), _plates, (v) => setState(() => _plates = v)),
          const SizedBox(height: 12),
          _spacingSelector('Шаг стоек', _wallSpacing, (v) => setState(() => _wallSpacing = v)),
        ]),
        _card('Проёмы (окна/двери)', [
          ..._openings.map((op) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(op.displayLabel, style: const TextStyle(fontSize: 14)),
            subtitle: Text('${op.wall.label} · ${op.positionLabel}'),
            trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _openings.removeWhere((o) => o.id == op.id))),
          )),
          OutlinedButton.icon(onPressed: () => _editOpening(null), icon: const Icon(Icons.add), label: const Text('Добавить проём')),
        ]),
        _card('Перекрёстное утепление стен', [
          _dd('Сечение досок (поперёк)', battensFor(_lt), _crossBatten, (v) => setState(() => _crossBatten = v)),
          const SizedBox(height: 12),
          _spacingSelector('Шаг досок (нар./внутр.)', _wallInsSpacing, (v) => setState(() => _wallInsSpacing = v)),
        ]),
      ],
    );
  }

  // --- 4. ПЕРЕКРЫТИЯ ---
  Widget _buildCeilingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('Межэтажные перекрытия (2-3 этаж)', [
          Text('Рассчитываются автоматически на основе лаг пола, если этажей > 1.', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
        ]),
      ],
    );
  }

  // --- 5. ПЕРЕГОРОДКИ ---
  Widget _buildPartitionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('Внутренние перегородки', [
          Text('В разработке. (Планируется расчет стоек 50х100 с обшивкой ГКЛ).', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
        ]),
      ],
    );
  }

  // --- 6. ЧЕРДАК ---
  Widget _buildAtticTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('Чердачное перекрытие (верхняя обвязка)', [
          _spacingSelector('Шаг балок чердака', _floorSpacing, (v) => setState(() => _floorSpacing = v)),
        ]),
        _card('Перекрёстное утепление чердака', [
          _dd('Сечение досок (поперёк)', battensFor(_lt), _crossBatten, (v) => setState(() => _crossBatten = v)),
          const SizedBox(height: 12),
          _spacingSelector('Шаг досок утепления', _roofInsSpacing, (v) => setState(() => _roofInsSpacing = v)),
        ]),
      ],
    );
  }

  // --- 7. КРЫША ---
  Widget _buildRoofTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card('Стропильная система', [
          _dd('Стропила', sectionsFor(_lt), _rafters, (v) => setState(() => _rafters = v)),
          const SizedBox(height: 12),
          _spacingSelector('Шаг стропил', _roofSpacing, (v) => setState(() => _roofSpacing = v)),
        ]),
        _card('Обрешётка и Кровля', [
          _dd('Обрешётка', battensFor(_lt), _batten, (v) => setState(() => _batten = v)),
          _dd('Контробрешётка', counterBattensFor(_lt), _cBatten, (v) => setState(() => _cBatten = v)),
        ]),
        _card('Перекрёстное утепление крыши (изнутри)', [
          _dd('Сечение досок', battensFor(_lt), _crossBatten, (v) => setState(() => _crossBatten = v)),
          const SizedBox(height: 12),
          _spacingSelector('Шаг досок', _roofInsSpacing, (v) => setState(() => _roofInsSpacing = v)),
        ]),
      ],
    );
  }

  // --- ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ---

  Future<void> _editOpening(Opening? existing) async {
    final result = await showModalBottomSheet<Opening>(
      context: context,
      isScrollControlled: true,
      builder: (_) => OpeningEditorSheet(initial: existing, wallHeightMm: widget.dimensions.wallHeightM * 1000),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (existing == null) {
        _openings.add(result);
      } else {
        final i = _openings.indexWhere((o) => o.id == existing.id);
        if (i >= 0) _openings[i] = result;
      }
    });
  }

  Widget _card(String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16), 
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)), 
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)), const SizedBox(height: 12), ...children])
  );
  
  Widget _dd(String label, List<LumberSection> items, LumberSection current, ValueChanged<LumberSection> cb) => Padding(
    padding: const EdgeInsets.only(bottom: 8), 
    child: Row(children: [Expanded(child: Text(label)), DropdownButton<LumberSection>(value: current, dropdownColor: Theme.of(context).colorScheme.surface, items: items.map((s) => DropdownMenuItem(value: s, child: Text(s.displayLabel, style: const TextStyle(fontSize: 13)))).toList(), onChanged: (x) => x != null ? cb(x) : null)])
  );

  Widget _spacingSelector(String label, int current, ValueChanged<int> cb) {
    final presets = [400, 500, 600];
    final useCustom = !presets.contains(current);
    final ctrl = TextEditingController(text: useCustom ? current.toString() : '');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (final v in presets) ButtonSegment(value: v, label: Text('$v')),
            const ButtonSegment(value: -1, label: Text('Свой')),
          ],
          selected: {useCustom ? -1 : current},
          onSelectionChanged: (s) {
            final v = s.first;
            if (v == -1) {
              if (ctrl.text.isEmpty) ctrl.text = current.toString();
              setState(() {}); // Обновить UI для поля ввода
            } else {
              cb(v);
            }
          },
        ),
        if (useCustom) ...[
          const SizedBox(height: 10),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Свой шаг', suffixText: 'мм'),
            onChanged: (v) {
              final p = int.tryParse(v);
              if (p != null && p >= 200 && p <= 1200) cb(p);
            },
          ),
        ]
      ],
    );
  }
}
