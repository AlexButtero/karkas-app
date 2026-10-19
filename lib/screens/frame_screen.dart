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

class _FrameScreenState extends State<FrameScreen> {
  late LumberMaterialType _lt;
  late LumberSection _studs, _plates, _joists, _rafters;
  late LumberSection _batten, _cBatten;
  late int _battenSpacing;
  late List<Opening> _openings;
  late InsulationType _ins;
  late double _insT;
  late SheathingType _sheath;

  @override
  void initState() {
    super.initState();
    final p = widget.initialParams ?? FrameParams();
    _lt = p.lumberType;
    _studs = p.studs; _plates = p.plates; _joists = p.joists; _rafters = p.rafters;
    _batten = p.batten; _cBatten = p.counterBatten; _battenSpacing = p.battenSpacingMm;
    _ins = p.insulation; _insT = p.insulationThickness; _sheath = p.sheathing;
    _openings = p.openings.isEmpty ? Opening.defaults() : List.of(p.openings);
  }

  FrameParams _params() => FrameParams(
        lumberType: _lt, studs: _studs, plates: _plates, joists: _joists, rafters: _rafters,
        batten: _batten, counterBatten: _cBatten, battenSpacingMm: _battenSpacing,
        openings: _openings, insulation: _ins, insulationThickness: _insT, sheathing: _sheath,
      );

  MaterialEstimate _calc() => MaterialEstimate.fromDimensions(
        widget.dimensions,
        studs: _studs, plates: _plates, joists: _joists, rafters: _rafters,
        batten: _batten, counterBatten: _cBatten, battenSpacingMm: _battenSpacing,
        openings: _openings, insulation: _ins, insulationThicknessMm: _insT,
      );

  void _changeType(LumberMaterialType t) {
    setState(() {
      _lt = t;
      final set = sectionsFor(t);
      final bset = battensFor(t);
      final cset = counterBattensFor(t);
      _studs = set[1]; _plates = set[1]; _rafters = set[1]; _joists = set[2];
      _batten = bset[0]; _cBatten = cset[0];
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final e = _calc();
    final totalArea = _openings.fold<double>(0.0, (s, o) => s + o.areaM2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каркас и материалы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_in_ar_outlined),
            tooltip: 'Показать 3D',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => FrameVisualizationScreen(dimensions: widget.dimensions, params: _params()),
            )),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _chip(context, '${widget.dimensions.lengthM.toInt()} × ${widget.dimensions.widthM.toInt()} м'),
                if (!widget.dimensions.isAFrame) _chip(context, '${widget.dimensions.wallHeightM} м стены'),
                _chip(context, '${widget.dimensions.roofPitchDeg.toInt()}°'),
                _chip(context, 'шаг ${widget.dimensions.studSpacingMm.toInt()} мм'),
              ],
            ),
            const SizedBox(height: 16),
            
            _card(context, 'Тип материала', [
              SegmentedButton<LumberMaterialType>(
                showSelectedIcon: false,
                segments: LumberMaterialType.values.map((t) => ButtonSegment(value: t, label: Text(t.label))).toList(),
                selected: {_lt},
                onSelectionChanged: (s) => _changeType(s.first),
              ),
            ]),
            const SizedBox(height: 12),

            _card(context, 'Сечения', [
              if (widget.dimensions.isAFrame) ...[
                _dd(context, 'Стропила (стены)', sectionsFor(_lt), _rafters, (v) => setState(() => _rafters = v)),
              ] else ...[
                _dd(context, 'Стойки', sectionsFor(_lt), _studs, (v) => setState(() => _studs = v)),
                _dd(context, 'Обвязка', sectionsFor(_lt), _plates, (v) => setState(() => _plates = v)),
                _dd(context, 'Стропила', sectionsFor(_lt), _rafters, (v) => setState(() => _rafters = v)),
              ],
              _dd(context, 'Лаги', sectionsFor(_lt), _joists, (v) => setState(() => _joists = v)),
            ]),
            const SizedBox(height: 12),

            _card(context, 'Кровельная обрешётка', [
              _dd(context, 'Обрешётка', battensFor(_lt), _batten, (v) => setState(() => _batten = v)),
              _dd(context, 'Контробрешётка', counterBattensFor(_lt), _cBatten, (v) => setState(() => _cBatten = v)),
              const SizedBox(height: 8),
              Text('Шаг обрешётки', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
              const SizedBox(height: 6),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: kBattenSpacingOptionsMm.map((mm) => ButtonSegment(value: mm, label: Text('$mm'))).toList(),
                selected: {_battenSpacing},
                onSelectionChanged: (s) => setState(() => _battenSpacing = s.first),
              ),
            ]),
            const SizedBox(height: 12),

            _card(context, 'Проёмы', [
              if (_openings.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('Нет проёмов.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))))
              else
                ..._openings.map((op) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(op.type == OpeningType.window ? Icons.window_outlined : Icons.door_front_door_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(op.displayLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('${op.wall.label} · ${op.positionLabel}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                      ])),
                      IconButton(onPressed: () => _editOpening(op), icon: const Icon(Icons.edit_outlined, size: 18), color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      IconButton(onPressed: () => setState(() => _openings.removeWhere((o) => o.id == op.id)), icon: const Icon(Icons.close, size: 18), color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    ],
                  ),
                )),
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: () => _editOpening(null), icon: const Icon(Icons.add, size: 18), label: const Text('Добавить проём')),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Площадь проёмов', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13)),
                Text('${totalArea.toStringAsFixed(2)} м²', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ]),
            const SizedBox(height: 12),

            _card(context, 'Утепление и обшивка', [
              SegmentedButton<InsulationType>(
                showSelectedIcon: false,
                segments: InsulationType.values.map((e) => ButtonSegment(value: e, label: Text(e.label))).toList(),
                selected: {_ins},
                onSelectionChanged: (s) => setState(() => _ins = s.first),
              ),
              const SizedBox(height: 8),
              SegmentedButton<double>(
                showSelectedIcon: false,
                segments: const [ButtonSegment(value: 100.0, label: Text('100')), ButtonSegment(value: 150.0, label: Text('150')), ButtonSegment(value: 200.0, label: Text('200')), ButtonSegment(value: 250.0, label: Text('250'))],
                selected: {_insT},
                onSelectionChanged: (s) => setState(() => _insT = s.first),
              ),
              const SizedBox(height: 8),
              SegmentedButton<SheathingType>(
                showSelectedIcon: false,
                segments: SheathingType.values.map((e) => ButtonSegment(value: e, label: Text(e.label))).toList(),
                selected: {_sheath},
                onSelectionChanged: (s) => setState(() => _sheath = s.first),
              ),
            ]),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Материалы', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _kv(context, 'Пиломатериалы', '${e.totalLumberMeters.toStringAsFixed(1)} п.м. · ${e.totalLumberVolume.toStringAsFixed(2)} м³'),
                _kv(context, 'Обшивка', '${e.osbSheets} листов'),
                _kv(context, 'Утеплитель', '${e.insulationVolume.toStringAsFixed(1)} м³'),
                _kv(context, 'Крепёж', '≈ ${e.fastenersKg.toStringAsFixed(0)} кг'),
                if (widget.dimensions.isAFrame) 
                  _kv(context, 'Особенность', 'Стены = Крыша (А-фрейм)'),
              ]),
            ),
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
            child: const Text('Смета', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext c, String t) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Theme.of(c).colorScheme.surface, borderRadius: BorderRadius.circular(10)), child: Text(t, style: const TextStyle(fontSize: 13)));
  
  Widget _card(BuildContext c, String title, List<Widget> children) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(c).colorScheme.surface, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)), const SizedBox(height: 10), ...children]));
  
  Widget _dd(BuildContext c, String label, List<LumberSection> items, LumberSection current, ValueChanged<LumberSection> cb) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text(label)), DropdownButton<LumberSection>(value: current, dropdownColor: Theme.of(c).colorScheme.surface, items: items.map((s) => DropdownMenuItem(value: s, child: Text(s.displayLabel, style: const TextStyle(fontSize: 13)))).toList(), onChanged: (x) => x != null ? cb(x) : null)]));
  
  Widget _kv(BuildContext c, String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(k, style: TextStyle(color: Theme.of(c).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13))), Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))]));
}
