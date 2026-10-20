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
  late LumberSection _batten, _cBatten;
  
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
    _batten = p.batten; _cBatten = p.counterBatten;
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
        batten: _batten, counterBatten: _cBatten,
        wallStudSpacingMm: _wallSpacing, floorJoistSpacingMm: _floorSpacing, roofRafterSpacingMm: _roofSpacing,
        wallCrossInsulationSpacingMm: _wallInsSpacing, roofCrossInsulationSpacingMm: _roofInsSpacing,
        openings: _openings, insulation: _ins, insulationThickness: _insT, sheathing: _sheath,
        bottomPlateType: _bpType,
      );

  MaterialEstimate _calc() => MaterialEstimate.fromDimensions(
        widget.dimensions,
        studs: _studs, plates: _plates, joists: _joists, rafters: _rafters,
        batten: _batten, counterBatten: _cBatten, battenSpacingMm: _roofSpacing,
        openings: _openings, insulation: _ins, insulationThicknessMm: _insT,
        bottomPlateType: _bpType,
      );

  @override
  Widget build(BuildContext context) {
    final e = _calc();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Проектирование каркаса'),
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
            _buildGrillageTab(context),
            _buildFloorsTab(context),
            _buildWallsTab(context),
            _buildCeilingsTab(context),
            _buildPartitionsTab(context),
            _buildAtticTab(context),
            _buildRoofTab(context),
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

  // --- ВКЛАДКА 1: РОСТВЕРК ---
  Widget _buildGrillageTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(context, 'Нижняя обвязка (Ростверк)', [
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
        const SizedBox(height: 12),
        _card(context, 'Центральные балки', [
          Text('Количество балок: ${widget.dimensions.centralBeamCount}', style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ],
    );
  }

  // --- ВКЛАДКА 2: ПОЛЫ ---
  Widget _buildFloorsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(context, 'Лаги пола', [
          _dd(context, 'Сечение лаг', sectionsFor(_lt), _joists, (v) => setState(() => _joists = v)),
          const SizedBox(height: 12),
          _spacingSelector(context, 'Шаг лаг', _floorSpacing, (v) => setState(() => _floorSpacing = v)),
        ]),
        const SizedBox(height: 12),
        _card(context, 'Перекрёстное утепление пола', [
          _spacingSelector(context, 'Шаг досок под утепление', _wallInsSpacing, (v) => setState(() => _wallInsSpacing = v)),
        ]),
      ],
    );
  }

  // --- ВКЛАДКА 3: СТЕНЫ ---
  Widget _buildWallsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(context, 'Стойки и обвязка', [
          _dd(context, 'Стойки', sectionsFor(_lt), _studs, (v) => setState(() => _studs = v)),
          _dd(context, 'Верхняя обвязка', sectionsFor(_lt), _plates, (v) => setState(() => _plates = v)),
          const SizedBox(height: 12),
          _spacingSelector(context, 'Шаг стоек', _wallSpacing, (v) => setState(() => _wallSpacing = v)),
        ]),
        const SizedBox(height: 12),
        _card(context, 'Проёмы (окна/двери)', [
          ..._openings.map((op) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(op.displayLabel, style: const TextStyle(fontSize: 14)),
            subtitle: Text('${op.wall.label} · ${op.positionLabel}'),
            trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _openings.removeWhere((o) => o.id == op.id))),
          )),
          OutlinedButton.icon(onPressed: () => _editOpening(null), icon: const Icon(Icons.add), label: const Text('Добавить проём')),
        ]),
        const SizedBox(height: 12),
        _card(context, 'Перекрёстное утепление стен', [
          _spacingSelector(context, 'Шаг досок (наружнее/внутреннее)', _wallInsSpacing, (v) => setState(() => _wallInsSpacing = v)),
        ]),
      ],
    );
  }

  // --- ВКЛАДКА 4: ПЕРЕКРЫТИЯ ---
  Widget _buildCeilingsTab(BuildContext context) {
    return Center(child: Text('Настройки перекрытий 2-го и 3-го этажа (в разработке)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))));
  }

  // --- ВКЛАДКА 5: ПЕРЕГОРОДКИ ---
  Widget _buildPartitionsTab(BuildContext context) {
    return Center(child: Text('Настройки внутренних перегородок (в разработке)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))));
  }

  // --- ВКЛАДКА 6: ЧЕРДАК ---
  Widget _buildAtticTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(context, 'Чердачное перекрытие', [
          _spacingSelector(context, 'Шаг балок чердака', _floorSpacing, (v) => setState(() => _floorSpacing = v)),
          const SizedBox(height: 12),
          _spacingSelector(context, 'Шаг досок под утепление', _roofInsSpacing, (v) => setState(() => _roofInsSpacing = v)),
        ]),
      ],
    );
  }

  // --- ВКЛАДКА 7: КРЫША ---
  Widget _buildRoofTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(context, 'Стропильная система', [
          _dd(context, 'Стропила', sectionsFor(_lt), _rafters, (v) => setState(() => _rafters = v)),
          const SizedBox(height: 12),
          _spacingSelector(context, 'Шаг стропил', _roofSpacing, (v) => setState(() => _roofSpacing = v)),
        ]),
        const SizedBox(height: 12),
        _card(context, 'Обрешётка и Кровля', [
          _dd(context, 'Обрешётка', battensFor(_lt), _batten, (v) => setState(() => _batten = v)),
          _dd(context, 'Контробрешётка', counterBattensFor(_lt), _cBatten, (v) => setState(() => _cBatten = v)),
        ]),
        const SizedBox(height: 12),
        _card(context, 'Перекрёстное утепление крыши', [
          _spacingSelector(context, 'Шаг досок изнутри', _roofInsSpacing, (v) => setState(() => _roofInsSpacing = v)),
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

  Widget _card(BuildContext c, String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16), 
    decoration: BoxDecoration(color: Theme.of(c).colorScheme.surface, borderRadius: BorderRadius.circular(16)), 
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)), const SizedBox(height: 12), ...children])
  );
  
  Widget _dd(BuildContext c, String label, List<LumberSection> items, LumberSection current, ValueChanged<LumberSection> cb) => Padding(
    padding: const EdgeInsets.only(bottom: 8), 
    child: Row(children: [Expanded(child: Text(label)), DropdownButton<LumberSection>(value: current, dropdownColor: Theme.of(c).colorScheme.surface, items: items.map((s) => DropdownMenuItem(value: s, child: Text(s.displayLabel, style: const TextStyle(fontSize: 13)))).toList(), onChanged: (x) => x != null ? cb(x) : null)])
  );

  Widget _spacingSelector(BuildContext c, String label, int current, ValueChanged<int> cb) {
    final presets = [400, 500, 600];
    final useCustom = !presets.contains(current);
    final ctrl = TextEditingController(text: useCustom ? current.toString() : '');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Theme.of(c).colorScheme.onSurface.withValues(alpha: 0.7))),
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
