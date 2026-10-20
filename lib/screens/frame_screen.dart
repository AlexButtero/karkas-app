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
  late int _centralBeams;
  late String _projectName;

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
    _centralBeams = widget.dimensions.centralBeamCount;
    _projectName = widget.projectName ?? '';
    _openings = p.openings.isEmpty ? Opening.defaults() : List.of(p.openings);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  HouseDimensions get _activeDimensions => widget.dimensions.copyWith(centralBeamCount: _centralBeams);

  FrameParams _params() => FrameParams(
        lumberType: _lt, studs: _studs, plates: _plates, joists: _joists, rafters: _rafters,
        batten: _batten, counterBatten: _cBatten, crossBattens: _crossBatten,
        wallStudSpacingMm: _wallSpacing, floorJoistSpacingMm: _floorSpacing, roofRafterSpacingMm: _roofSpacing,
        wallCrossInsulationSpacingMm: _wallInsSpacing, roofCrossInsulationSpacingMm: _roofInsSpacing,
        openings: _openings, insulation: _ins, insulationThickness: _insT, sheathing: _sheath,
        bottomPlateType: _bpType,
      );

  MaterialEstimate _calc() => MaterialEstimate.fromDimensions(
        _activeDimensions,
        studs: _studs, plates: _plates, joists: _joists, rafters: _rafters,
        batten: _batten, counterBatten: _cBatten, crossBattens: _crossBatten,
        wallSpacingMm: _wallSpacing, floorSpacingMm: _floorSpacing, roofSpacingMm: _roofSpacing,
        wallInsSpacingMm: _wallInsSpacing, roofInsSpacingMm: _roofInsSpacing,
        openings: _openings, insulation: _ins, insulationThicknessMm: _insT,
        bottomPlateType: _bpType,
      );

  List<LumberSection> _getGrillageSections() {
    if (_lt == LumberMaterialType.edged) return [kEdgedSections[1], kEdgedSections[2], kEdgedSections[3]];
    return [kDryPlanedSections[1], kDryPlanedSections[2]];
  }

  @override
  Widget build(BuildContext context) {
    final e = _calc();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каркас дома'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_in_ar_outlined), tooltip: 'Показать весь дом',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => FrameVisualizationScreen(dimensions: _activeDimensions, params: _params()),
            )),
          ),
        ],
        bottom: TabBar(
          controller: _tabController, isScrollable: true, tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: '1. Ростверк'), Tab(text: '2. Полы'), Tab(text: '3. Стены'),
            Tab(text: '4. Перекрытия'), Tab(text: '5. Перегородки'), Tab(text: '6. Чердак'), Tab(text: '7. Крыша'),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildGrillageTab(e),
            _buildFloorsTab(e),
            _buildWallsTab(e),
            _buildCeilingsTab(e),
            _buildPartitionsTab(e),
            _buildAtticTab(e),
            _buildRoofTab(e),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: () {
              if (_projectName.isEmpty) { _askForProjectName(); return; }
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EstimateScreen(
                  estimate: e, sheathing: _sheath, dimensions: _activeDimensions, frameParams: _params(),
                  projectId: widget.projectId, projectName: _projectName, savedPrices: widget.savedPrices,
                ),
              ));
            },
            child: const Text('Общая смета (весь дом)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Future<void> _askForProjectName() async {
    final ctrl = TextEditingController(text: _projectName.isEmpty ? 'Мой дом' : _projectName);
    final name = await showDialog<String>(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('Название дома'), content: TextField(controller: ctrl, autofocus: true), 
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Сохранить'))]
      )
    );
    if (name != null && name.isNotEmpty) setState(() => _projectName = name);
  }

  Widget _buildActions(String elementName, MaterialEstimate e, bool showG, bool showF, bool showW, bool showR) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.view_in_ar, size: 18), label: const Text('3D'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => FrameVisualizationScreen(
                dimensions: _activeDimensions, params: _params(),
                initialShowGrillage: showG, initialShowFloors: showF, initialShowWalls: showW, initialShowRoof: showR,
              ),
            )),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            icon: const Icon(Icons.picture_as_pdf, size: 18), label: const Text('Смета элемента'),
            onPressed: () async {
              if (_projectName.isEmpty) { await _askForProjectName(); if (_projectName.isEmpty) return; }
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EstimateScreen(
                  estimate: e, sheathing: _sheath, dimensions: _activeDimensions, frameParams: _params(),
                  projectName: _projectName, elementType: elementName,
                ),
              ));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGrillageTab(MaterialEstimate e) {
    final secs = _getGrillageSections();
    final safeSec = secs.contains(_plates) ? _plates : secs[0];
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: TextEditingController(text: _projectName), decoration: const InputDecoration(labelText: 'Название проекта'), onChanged: (v) => setState(() => _projectName = v)),
      const SizedBox(height: 16),
      _card('Пиломатериал', [
        SegmentedButton<LumberMaterialType>(showSelectedIcon: false, segments: LumberMaterialType.values.map((t) => ButtonSegment(value: t, label: Text(t.label))).toList(), selected: {_lt}, onSelectionChanged: (s) { setState(() { _lt = s.first; _plates = _getGrillageSections()[0]; _bpType = BottomPlateType.pack3; }); }),
        const SizedBox(height: 12),
        _dd('Сечение', secs, safeSec, (v) { setState(() { _plates = v; if (v.widthMm == 150) { _bpType = BottomPlateType.solid; } else if (_bpType == BottomPlateType.solid) { _bpType = BottomPlateType.pack3; } }); }),
      ]),
      _card('Сборка', [
        SegmentedButton<BottomPlateType>(showSelectedIcon: false, segments: BottomPlateType.values.where((t) { if (safeSec.widthMm == 150) return t == BottomPlateType.solid; return t != BottomPlateType.solid; }).map((t) => ButtonSegment(value: t, label: Text(t.label))).toList(), selected: {_bpType}, onSelectionChanged: (s) => setState(() => _bpType = s.first)),
      ]),
      _card('Центральные балки', [
        SegmentedButton<int>(showSelectedIcon: false, segments: const [ButtonSegment(value: 0, label: Text('Нет')), ButtonSegment(value: 1, label: Text('1')), ButtonSegment(value: 2, label: Text('2'))], selected: {_centralBeams}, onSelectionChanged: (s) => setState(() => _centralBeams = s.first)),
      ]),
      _buildActions('Ростверк', e, true, false, false, false),
    ]);
  }

  Widget _buildFloorsTab(MaterialEstimate e) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _card('Лаги и утепление', [
        _dd('Сечение лаг', sectionsFor(_lt), _joists, (v) => setState(() => _joists = v)),
        const SizedBox(height: 12),
        _spacingSelector('Шаг лаг', _floorSpacing, (v) => setState(() => _floorSpacing = v)),
        const SizedBox(height: 16),
        _dd('Доски перекр. утепления', battensFor(_lt), _crossBatten, (v) => setState(() => _crossBatten = v)),
        const SizedBox(height: 12),
        _spacingSelector('Шаг досок утепления', _wallInsSpacing, (v) => setState(() => _wallInsSpacing = v)),
      ]),
      _buildActions('Полы', e, true, true, false, false),
    ]);
  }

  Widget _buildWallsTab(MaterialEstimate e) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _card('Каркас и проёмы', [
        _dd('Стойки', sectionsFor(_lt), _studs, (v) => setState(() => _studs = v)),
        _dd('Обвязка', sectionsFor(_lt), _plates, (v) => setState(() => _plates = v)),
        const SizedBox(height: 12),
        _spacingSelector('Шаг стоек', _wallSpacing, (v) => setState(() => _wallSpacing = v)),
        const SizedBox(height: 16),
        ..._openings.map((op) => ListTile(contentPadding: EdgeInsets.zero, title: Text(op.displayLabel), trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _openings.removeWhere((o) => o.id == op.id))))),
        OutlinedButton.icon(onPressed: () => _editOpening(null), icon: const Icon(Icons.add), label: const Text('Добавить проём')),
      ]),
      _card('Перекрёстное утепление стен', [
        _dd('Доски утепления', battensFor(_lt), _crossBatten, (v) => setState(() => _crossBatten = v)),
        const SizedBox(height: 12),
        _spacingSelector('Шаг досок', _wallInsSpacing, (v) => setState(() => _wallInsSpacing = v)),
      ]),
      _buildActions('Стены', e, true, true, true, false),
    ]);
  }

  Widget _buildCeilingsTab(MaterialEstimate e) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _card('Межэтажные перекрытия', [Text('Рассчитываются автоматически (Лаги 2+ этажей). Настройки берутся из вкладки "Полы".', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)))]),
      _buildActions('Перекрытия', e, true, true, false, false),
    ]);
  }

  Widget _buildPartitionsTab(MaterialEstimate e) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _card('Внутренние перегородки', [const Text('В разработке (50х100 + ГКЛ).')]),
      _buildActions('Перегородки', e, true, true, true, false),
    ]);
  }

  Widget _buildAtticTab(MaterialEstimate e) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _card('Балки и утепление чердака', [
        _spacingSelector('Шаг балок', _floorSpacing, (v) => setState(() => _floorSpacing = v)),
        const SizedBox(height: 16),
        _dd('Доски перекр. утепления', battensFor(_lt), _crossBatten, (v) => setState(() => _crossBatten = v)),
        const SizedBox(height: 12),
        _spacingSelector('Шаг утепления', _roofInsSpacing, (v) => setState(() => _roofInsSpacing = v)),
      ]),
      _buildActions('Чердак', e, true, true, true, false),
    ]);
  }

  Widget _buildRoofTab(MaterialEstimate e) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _card('Стропильная система', [
        _dd('Стропила', sectionsFor(_lt), _rafters, (v) => setState(() => _rafters = v)),
        const SizedBox(height: 12),
        _spacingSelector('Шаг стропил', _roofSpacing, (v) => setState(() => _roofSpacing = v)),
      ]),
      _card('Обрешётка', [
        _dd('Обрешётка', battensFor(_lt), _batten, (v) => setState(() => _batten = v)),
        _dd('Контробрешётка', counterBattensFor(_lt), _cBatten, (v) => setState(() => _cBatten = v)),
      ]),
      _card('Утепление крыши', [
        _dd('Доски утепления', battensFor(_lt), _crossBatten, (v) => setState(() => _crossBatten = v)),
        const SizedBox(height: 12),
        _spacingSelector('Шаг', _roofInsSpacing, (v) => setState(() => _roofInsSpacing = v)),
      ]),
      _buildActions('Крыша', e, true, true, true, true),
    ]);
  }

  Future<void> _editOpening(Opening? existing) async {
    final result = await showModalBottomSheet<Opening>(context: context, isScrollControlled: true, builder: (_) => OpeningEditorSheet(initial: existing, wallHeightMm: widget.dimensions.wallHeightM * 1000));
    if (result == null || !mounted) return;
    setState(() { if (existing == null) { _openings.add(result); } else { final i = _openings.indexWhere((o) => o.id == existing.id); if (i >= 0) _openings[i] = result; } });
  }

  Widget _card(String title, List<Widget> children) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)), const SizedBox(height: 12), ...children]));
  
  Widget _dd(String label, List<LumberSection> items, LumberSection current, ValueChanged<LumberSection> cb) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Expanded(child: Text(label)), DropdownButton<LumberSection>(value: current, dropdownColor: Theme.of(context).colorScheme.surface, items: items.map((s) => DropdownMenuItem(value: s, child: Text(s.displayLabel, style: const TextStyle(fontSize: 13)))).toList(), onChanged: (x) => x != null ? cb(x) : null)]));

  Widget _spacingSelector(String label, int current, ValueChanged<int> cb) {
    final presets = [400, 500, 600];
    final useCustom = !presets.contains(current);
    final ctrl = TextEditingController(text: useCustom ? current.toString() : '');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
      const SizedBox(height: 8),
      SegmentedButton<int>(showSelectedIcon: false, segments: [for (final v in presets) ButtonSegment(value: v, label: Text('$v')), const ButtonSegment(value: -1, label: Text('Свой'))], selected: {useCustom ? -1 : current}, onSelectionChanged: (s) { final v = s.first; if (v == -1) { if (ctrl.text.isEmpty) ctrl.text = current.toString(); setState(() {}); } else { cb(v); } }),
      if (useCustom) ...[const SizedBox(height: 10), TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Свой шаг', suffixText: 'мм'), onChanged: (v) { final p = int.tryParse(v); if (p != null && p >= 200 && p <= 1200) cb(p); })],
    ]);
  }
}
