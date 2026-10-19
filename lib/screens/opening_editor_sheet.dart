import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/opening.dart';

class OpeningEditorSheet extends StatefulWidget {
  final Opening? initial;
  final double wallHeightMm;
  const OpeningEditorSheet({this.initial, required this.wallHeightMm, super.key});

  @override
  State<OpeningEditorSheet> createState() => _OpeningEditorSheetState();
}

class _OpeningEditorSheetState extends State<OpeningEditorSheet> {
  late OpeningType _type;
  late WallSide _wall;
  late int _quantity;
  late final TextEditingController _widthCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _sillCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _type = i?.type ?? OpeningType.window;
    _wall = i?.wall ?? WallSide.front;
    _quantity = i?.quantity ?? 1;
    _widthCtrl = TextEditingController(text: (i?.widthMm ?? 1500).toInt().toString());
    _heightCtrl = TextEditingController(text: (i?.heightMm ?? 1500).toInt().toString());
    _sillCtrl = TextEditingController(text: (i?.sillHeightMm ?? 900).toInt().toString());
  }

  @override
  void dispose() {
    _widthCtrl.dispose(); _heightCtrl.dispose(); _sillCtrl.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final w = _parse(_widthCtrl)!;
    final h = _parse(_heightCtrl)!;
    final s = _type == OpeningType.door ? 0.0 : (_parse(_sillCtrl) ?? 0);

    if (widget.wallHeightMm > 0 && s + h > widget.wallHeightMm) {
      final max = (widget.wallHeightMm - s).toInt();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Верх проёма выходит за стену. Максимальная высота: $max мм.')));
      return;
    }

    Navigator.of(context).pop(Opening(
      id: widget.initial?.id ?? Opening.generateId(),
      type: _type,
      widthMm: w,
      heightMm: h,
      sillHeightMm: s,
      quantity: _quantity,
      wall: _wall,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 18),
              Text(widget.initial == null ? 'Новый проём' : 'Редактировать проём', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SegmentedButton<OpeningType>(
                showSelectedIcon: false,
                segments: OpeningType.values.map((t) => ButtonSegment(value: t, label: Text(t.label))).toList(),
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  if (_type == OpeningType.door) _sillCtrl.text = '0';
                  if (_type == OpeningType.window && _sillCtrl.text == '0') _sillCtrl.text = '900';
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _NumField(controller: _widthCtrl, label: 'Ширина', suffix: 'мм', min: 100, max: 5000)),
                  const SizedBox(width: 12),
                  Expanded(child: _NumField(controller: _heightCtrl, label: 'Высота', suffix: 'мм', min: 100, max: widget.wallHeightMm > 0 ? widget.wallHeightMm : 5000)),
                ],
              ),
              if (_type == OpeningType.window) ...[
                const SizedBox(height: 12),
                _NumField(controller: _sillCtrl, label: 'От пола', suffix: 'мм', min: 0, max: 2000),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Text('Количество')),
                  IconButton(onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null, icon: const Icon(Icons.remove_circle_outline)),
                  Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  IconButton(onPressed: _quantity < 20 ? () => setState(() => _quantity++) : null, icon: const Icon(Icons.add_circle_outline)),
                ],
              ),
              const SizedBox(height: 16),
              Text('Стена', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: WallSide.values.map((w) => ChoiceChip(
                  label: Text(w.label),
                  selected: _wall == w,
                  onSelected: (_) => setState(() => _wall = w),
                )).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final double min;
  final double max;

  const _NumField({required this.controller, required this.label, required this.suffix, required this.min, required this.max});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: (v) {
        final parsed = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
        if (parsed == null) return 'Введите число';
        if (parsed < min || parsed > max) return '${min.toInt()}–${max.toInt()}';
        return null;
      },
    );
  }
}
