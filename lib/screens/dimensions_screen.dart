import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/house_dimensions.dart';
import '../models/house_style.dart';
import 'frame_screen.dart';

class DimensionsScreen extends StatefulWidget {
  final HouseStyle? style;
  final HouseDimensions? initialDimensions;

  const DimensionsScreen({this.style, this.initialDimensions, super.key});
  
  @override
  State<DimensionsScreen> createState() => _DimensionsScreenState();
}

class _DimensionsScreenState extends State<DimensionsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _lengthCtrl;
  late final TextEditingController _widthCtrl;
  late final TextEditingController _wallCtrl;
  late final TextEditingController _pitchCtrl;
  late final TextEditingController _eaveCtrl;
  late final TextEditingController _groundCtrl;
  late final TextEditingController _customSpacingCtrl;
  
  late int _floors;
  late double _studSpacing;
  static const _presets = <double>[400, 500, 600];
  late bool _useCustomSpacing;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDimensions;
    _lengthCtrl = TextEditingController(text: d != null ? _fmt(d.lengthM, 0) : '8');
    _widthCtrl = TextEditingController(text: d != null ? _fmt(d.widthM, 0) : '6');
    _wallCtrl = TextEditingController(text: d != null ? _fmt(d.wallHeightM) : '2,7');
    _pitchCtrl = TextEditingController(text: d != null ? _fmt(d.roofPitchDeg, 0) : '30');
    _eaveCtrl = TextEditingController(text: d != null ? _fmt(d.eaveOverhangM) : '0,5');
    _groundCtrl = TextEditingController(text: d != null ? _fmt(d.groundClearanceM) : '0,15');
    
    _floors = d?.floors ?? 1;
    _studSpacing = d?.studSpacingMm ?? 600;
    _useCustomSpacing = !_presets.contains(_studSpacing);
    _customSpacingCtrl = TextEditingController(text: _useCustomSpacing ? _fmt(_studSpacing, 0) : '');
  }

  @override
  void dispose() {
    _lengthCtrl.dispose(); _widthCtrl.dispose(); _wallCtrl.dispose();
    _pitchCtrl.dispose(); _eaveCtrl.dispose(); _groundCtrl.dispose();
    _customSpacingCtrl.dispose();
    super.dispose();
  }

  static double? _parse(String? s) {
    if (s == null) return null;
    final t = s.trim().replaceAll(',', '.');
    return t.isEmpty ? null : double.tryParse(t);
  }

  static String _fmt(double v, [int d = 1]) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(d).replaceAll('.', ',');
  }

  HouseDimensions? _readModel() {
    final l = _parse(_lengthCtrl.text);
    final w = _parse(_widthCtrl.text);
    final h = _parse(_wallCtrl.text);
    final p = _parse(_pitchCtrl.text);
    final e = _parse(_eaveCtrl.text) ?? 0.5;
    final g = _parse(_groundCtrl.text) ?? 0.15;
    final isA = widget.style?.isAFrame ?? false;
    
    if (l == null || w == null || p == null) return null;
    if (!isA && h == null) return null;
    
    double s;
    if (_useCustomSpacing) {
      final cs = _parse(_customSpacingCtrl.text);
      if (cs == null || cs < 200 || cs > 1200) return null;
      s = cs;
    } else {
      s = _studSpacing;
    }
    
    return HouseDimensions(
      lengthM: l, widthM: w, wallHeightM: isA ? 0 : h!,
      roofPitchDeg: p, floors: _floors, studSpacingMm: s,
      eaveOverhangM: isA ? 0 : e, groundClearanceM: g, isAFrame: isA,
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = _readModel();
    final isA = widget.style?.isAFrame ?? false;
    final hideEave = isA || (widget.style != null && widget.style!.eaveOverhangM == 0.0);
    final hasStone = widget.style?.hasStonePlinth ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(widget.style != null ? widget.style!.name : 'Размеры дома')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.style != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text('Стиль: ${widget.style!.tagline}', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
              _num(_lengthCtrl, 'Длина дома', 'м', 1, 30),
              const SizedBox(height: 12),
              _num(_widthCtrl, 'Ширина дома', 'м', 1, 30),
              const SizedBox(height: 12),
              
              if (!isA) ...[
                _num(_wallCtrl, 'Высота стен', 'м', 2, 5),
                const SizedBox(height: 12),
              ],
              
              _num(_pitchCtrl, 'Угол крыши', '°', 0, 60),
              const SizedBox(height: 12),
              
              if (hideEave)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Theme.of(context).dividerColor)),
                  child: Row(children: [Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)), const SizedBox(width: 8), Expanded(child: Text(isA ? 'Для стиля А-фрейм свесы не предусмотрены (стены = крыша).' : 'Для этого стиля карнизный свес не предусмотрен.', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))))]),
                )
              else
                Row(
                  children: [
                    Expanded(child: _num(_eaveCtrl, 'Свес крыши', 'м', 0, 2)),
                    const SizedBox(width: 12),
                    Expanded(child: _num(_groundCtrl, hasStone ? 'Каменный цоколь' : 'Высота цоколя', 'м', 0.1, 1)),
                  ],
                ),
              
              if (isA) ...[
                const SizedBox(height: 12),
                Row(children: [Expanded(child: _num(_groundCtrl, 'Высота цоколя', 'м', 0.1, 1))]),
              ],

              const SizedBox(height: 8),
              Text(hasStone ? 'Стиль Шале подразумевает каменный цоколь (рекомендуется 0.6 м).' : 'Согласно СП 332.1325800.2017, низ стены должен быть не менее 150 мм над землёй.', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
              const SizedBox(height: 24),
              
              Text('Этажность', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [ButtonSegment(value: 1, label: Text('1')), ButtonSegment(value: 2, label: Text('2')), ButtonSegment(value: 3, label: Text('3'))],
                selected: {_floors},
                onSelectionChanged: isA ? null : (s) => setState(() => _floors = s.first),
              ),
              const SizedBox(height: 24),
              
              Text('Шаг стоек каркаса, мм', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
              const SizedBox(height: 8),
              SegmentedButton<double>(
                showSelectedIcon: false,
                segments: [
                  for (final v in _presets) ButtonSegment(value: v, label: Text('${v.toInt()}')),
                  const ButtonSegment(value: -1, label: Text('Свой')),
                ],
                selected: {_useCustomSpacing ? -1 : _studSpacing},
                onSelectionChanged: (s) {
                  final v = s.first;
                  setState(() {
                    if (v == -1) {
                      _useCustomSpacing = true;
                      if (_customSpacingCtrl.text.isEmpty) _customSpacingCtrl.text = _fmt(_studSpacing, 0);
                    } else {
                      _useCustomSpacing = false;
                      _studSpacing = v;
                    }
                  });
                },
              ),
              if (_useCustomSpacing) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customSpacingCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  decoration: const InputDecoration(labelText: 'Свой шаг', suffixText: 'мм', hintText: '200–1200'),
                  validator: (v) {
                    final p = _parse(v);
                    if (p == null) return 'Введите число';
                    if (p < 200 || p > 1200) return '200–1200 мм';
                    return null;
                  },
                  onChanged: (v) {
                    final p = _parse(v);
                    if (p != null && p >= 200 && p <= 1200) setState(() => _studSpacing = p);
                  },
                ),
              ],
              const SizedBox(height: 24),
              
              if (model != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Расчёт', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      _row(context, 'Площадь', '${_fmt(model.footprintArea)} м²'),
                      _row(context, 'Периметр', '${_fmt(model.perimeter)} м'),
                      _row(context, 'Высота в коньке', '${_fmt(model.totalHeight)} м'),
                      _row(context, isA ? 'Стропил (стен)' : 'Стоек', '${model.studsEstimate} шт'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              final m = _readModel();
              if (m == null) return;
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FrameScreen(
                  dimensions: m,
                  initialParams: widget.style?.params,
                ),
              ));
            },
            child: const Text('Продолжить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _num(TextEditingController c, String label, String suffix, double min, double max) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: (v) {
        final p = _parse(v);
        if (p == null) return 'Введите число';
        if (p < min || p > max) return '${min.toInt()}–${max.toInt()}';
        return null;
      },
    );
  }

  Widget _row(BuildContext c, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: TextStyle(color: Theme.of(c).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
            Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
