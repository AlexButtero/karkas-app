import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/house_dimensions.dart';
import '../models/material_estimate.dart';
import '../models/frame_params.dart';
import '../data/project_repository.dart';

class EstimateScreen extends StatefulWidget {
  final MaterialEstimate estimate;
  final SheathingType sheathing;
  final HouseDimensions? dimensions;
  final FrameParams? frameParams;
  final int? projectId;
  final String? projectName;
  final Map<String, double>? savedPrices;
  final String? elementType; 

  const EstimateScreen({
    required this.estimate, required this.sheathing, this.dimensions, 
    this.frameParams, this.projectId, this.projectName, this.savedPrices, 
    this.elementType, super.key
  });
  
  @override
  State<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends State<EstimateScreen> with WidgetsBindingObserver {
  late final List<_Item> _items;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final e = widget.estimate;
    
    var allItems = [
      for (final l in e.lumber)
        _Item(
          l.name, 'м³', l.volume, l.meters, l.count, l.pieceLengthM, l.section.displayLabel,
          widget.savedPrices?[l.name]?.toString() ?? (l.name.contains('Обрешётка') ? '15000' : '18000')
        ),
      if (e.hasStonePlinth)
        _Item('Каменный цоколь (облицовка)', 'м²', (widget.dimensions!.lengthM + widget.dimensions!.widthM) * 2 * widget.dimensions!.groundClearanceM, 0, 0, 0, '', '3500'),
      if (e.rostverkNailsCount > 0)
        _Item('Гвозди 90 мм (для ростверка)', 'кг', e.rostverkNailsWeight, 0, 0, 0, '', '350'),
      _Item(widget.sheathing.label, 'лист', e.osbSheets.toDouble(), 0, 0, 0, '', widget.savedPrices?[widget.sheathing.label]?.toString() ?? '800'),
      _Item('${e.insulation.label}, ${e.insulationThicknessMm.toInt()} мм', 'м³', e.insulationVolume, 0, 0, 0, '', widget.savedPrices?[e.insulation.label]?.toString() ?? '4500'),
      _Item('Крепёж (общий)', 'кг', e.fastenersKg, 0, 0, 0, '', widget.savedPrices?['Крепёж']?.toString() ?? '250'),
    ];

    if (widget.elementType != null) {
      final filter = widget.elementType!.toLowerCase();
      _items = allItems.where((i) {
        final name = i.name.toLowerCase();
        if (filter.contains('ростверк')) return name.contains('ростверк') || name.contains('гвозди');
        if (filter.contains('полы')) return name.contains('пола 1-го');
        if (filter.contains('перекрытия')) return name.contains('перекрытий 2+');
        if (filter.contains('чердак')) return name.contains('чердака');
        if (filter.contains('стены')) return name.contains('стойки') || name.contains('обвязка (верхняя)') || name.contains('обрамление') || name.contains('обрешетка стен');
        if (filter.contains('крыша')) return name.contains('стропила') || name.contains('обрешётка') || name.contains('контробрешётка') || name.contains('обрешетка крыши');
        if (filter.contains('перегородки')) return name.contains('перегородки');
        return false;
      }).toList();
    } else {
      _items = allItems;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _savePricesToDB(showSnackBar: false); 
    for (final i in _items) { i.ctrl.dispose(); }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _savePricesToDB(showSnackBar: false);
    }
  }

  Future<void> _savePricesToDB({bool showSnackBar = true}) async {
    if (widget.projectId == null) return;
    
    final old = await ProjectRepository.instance.getById(widget.projectId!);
    if (old != null) {
      await ProjectRepository.instance.update(old.copyWith(
        prices: {for (final i in _items) i.name: i.price},
        updatedAt: DateTime.now(),
      ));
      
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Цены сохранены'), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  double get _total => _items.fold(0.0, (s, i) => s + i.total);

  static String _f(double v, [int d = 0]) {
    if (v == v.roundToDouble()) return v.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
    return v.toStringAsFixed(d).replaceAll('.', ',');
  }

  Future<void> _exportPdf() async {
    final finalName = widget.projectName ?? 'Мой дом';
    final documentTitle = widget.elementType != null 
        ? '$finalName — ${widget.elementType}' 
        : '$finalName — Общая смета';

    setState(() => _exporting = true);
    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      final baseFont = pw.Font.ttf(fontData);
      final boldFont = pw.Font.ttf(boldFontData);

      final doc = pw.Document();
      
      final tableData = _items.map((i) => [
        i.sectionLabel.isEmpty ? i.name : '${i.name} ${i.sectionLabel}',
        i.actualSize,
        i.exactSizeCount,
        i.cuttingPlan,
        _f(i.qty, 2), 
        i.unit,
        '${_f(i.price)}', 
        '${_f(i.total)}'
      ]).toList();

      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        build: (ctx) => [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('СМЕТА МАТЕРИАЛОВ', style: pw.TextStyle(font: boldFont, fontSize: 22)), pw.SizedBox(height: 4), pw.Text('KARKAS — проектирование домов', style: pw.TextStyle(font: baseFont, fontSize: 12, color: PdfColors.grey600))]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(documentTitle, style: pw.TextStyle(font: boldFont, fontSize: 14)), 
              pw.Text(DateTime.now().toString().split(' ')[0], style: pw.TextStyle(font: baseFont, fontSize: 10, color: PdfColors.grey600))
            ])
          ]),
          pw.SizedBox(height: 10), pw.Divider(color: PdfColors.grey400), pw.SizedBox(height: 10),
          if (widget.dimensions != null && widget.elementType == null)
            pw.Container(padding: const pw.EdgeInsets.all(10), decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Габариты: ${_f(widget.dimensions!.lengthM, 0)} × ${_f(widget.dimensions!.widthM, 0)} м', style: pw.TextStyle(font: baseFont, fontSize: 10)), pw.Text('Этажей: ${widget.dimensions!.floors}', style: pw.TextStyle(font: baseFont, fontSize: 10)), pw.Text('Угол крыши: ${_f(widget.dimensions!.roofPitchDeg, 0)}°', style: pw.TextStyle(font: baseFont, fontSize: 10))])),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Позиция', 'Размер', 'Точное кол-во', 'К закупке (шт×мм)', 'Объем', 'Ед.', 'Цена (₽)', 'Сумма (₽)'], 
            data: tableData, 
            headerStyle: pw.TextStyle(font: boldFont, fontSize: 7, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800), 
            cellStyle: pw.TextStyle(font: baseFont, fontSize: 7), 
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 3),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50), 
            border: pw.TableBorder.symmetric(inside: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.center, 2: pw.Alignment.center, 3: pw.Alignment.center, 4: pw.Alignment.centerRight, 5: pw.Alignment.center, 6: pw.Alignment.centerRight, 7: pw.Alignment.centerRight},
          ),
          pw.SizedBox(height: 16),
          pw.Container(alignment: pw.Alignment.centerRight, padding: const pw.EdgeInsets.only(top: 10, right: 10), child: pw.RichText(text: pw.TextSpan(children: [pw.TextSpan(text: 'ИТОГО К ОПЛАТЕ:  ', style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.grey700)), pw.TextSpan(text: '${_f(_total)} ₽', style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColors.red800))]))),
          pw.Spacer(), pw.Divider(color: PdfColors.grey300), pw.Text('Смета сформирована в приложении KARKAS. Расчет является ориентировочным.', style: pw.TextStyle(font: baseFont, fontSize: 8, color: PdfColors.grey500)),
        ],
      ));

      final bytes = await doc.save();
      await Printing.sharePdf(bytes: bytes, filename: '$documentTitle.pdf');
    } catch (e) {
      if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка PDF: $e')));
    } finally { if (mounted) setState(() => _exporting = false); }
  }

  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      final excel = Excel.createExcel(); final sheet = excel['Смета'];
      excel.setDefaultSheet('Смета'); if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');

      final titleStyle = CellStyle(bold: true, fontSize: 16);
      final headerStyle = CellStyle(bold: true, backgroundColorHex: ExcelColor.fromHexString('#333333'), fontColorHex: ExcelColor.white);
      final boldStyle = CellStyle(bold: true);
      final moneyStyle = CellStyle(numberFormat: NumFormat.custom(formatCode: '# ##0'));

      int row = 0;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('СМЕТА МАТЕРИАЛОВ');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).cellStyle = titleStyle;
      row++;
      if (widget.projectName != null) { 
        final title = widget.elementType != null ? '${widget.projectName} — ${widget.elementType}' : widget.projectName!;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(title); 
      }
      row += 2;

      final headers = ['Позиция', 'Размер элемента', 'Точное кол-во', 'К закупке', 'Объем', 'Ед.', 'Цена (₽)', 'Сумма (₽)'];
      for (var i = 0; i < headers.length; i++) { final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row)); cell.value = TextCellValue(headers[i]); cell.cellStyle = headerStyle; }
      row++;

      for (final i in _items) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(i.sectionLabel.isEmpty ? i.name : '${i.name} ${i.sectionLabel}');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(i.actualSize);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(i.exactSizeCount);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(i.cuttingPlan);
        
        final qtyCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)); qtyCell.value = DoubleCellValue(i.qty); qtyCell.cellStyle = CellStyle(numberFormat: NumFormat.custom(formatCode: '0.00'));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = TextCellValue(i.unit);
        
        final priceCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)); priceCell.value = DoubleCellValue(i.price); priceCell.cellStyle = moneyStyle;
        final totalCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)); totalCell.value = DoubleCellValue(i.total); totalCell.cellStyle = moneyStyle;
        row++;
      }

      row++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('ИТОГО');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).cellStyle = boldStyle;
      final totalCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)); totalCell.value = DoubleCellValue(_total); totalCell.cellStyle = boldStyle.copyWith(numberFormat: NumFormat.custom(formatCode: '# ##0'));

      sheet.setColumnWidth(0, 30); sheet.setColumnWidth(1, 20); sheet.setColumnWidth(2, 15); sheet.setColumnWidth(3, 25); sheet.setColumnWidth(4, 12); sheet.setColumnWidth(5, 8); sheet.setColumnWidth(6, 15); sheet.setColumnWidth(7, 15);

      final fileBytes = excel.save(); if (fileBytes == null) throw Exception('Ошибка');
      final dir = await getTemporaryDirectory(); final file = File('${dir.path}/smeta_karkas.xlsx'); await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')], subject: 'Смета KARKAS');
    } catch (e) {
      if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка Excel: $e')));
    } finally { if (mounted) setState(() => _exporting = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.elementType != null ? 'Смета: ${widget.elementType}' : 'Общая смета'),
        actions: [
          if (widget.projectId != null)
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Сохранить цены',
              onPressed: () => _savePricesToDB(showSnackBar: true),
            )
        ],
      ),
      body: SafeArea(top: false, child: Column(children: [
        Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Итого', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))), const SizedBox(height: 4), Text('${_f(_total)} ₽', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text('${_items.length} позиций', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)))])),
        Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _items.length, itemBuilder: (_, i) {
          final item = _items[i];
          return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(item.sectionLabel.isEmpty ? item.name : '${item.name} ${item.sectionLabel}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))), 
              Text('${item.qty.toStringAsFixed(2)} ${item.unit}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)))
            ]),
            
            if (item.sectionLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Размер элемента: ${item.actualSize}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                    Text('Точное количество: ${item.exactSizeCount}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text('Вариант закупки: ${item.cuttingPlan}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 2),
                    Text('Всего: ${item.meters.toStringAsFixed(1)} п.м.', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            Row(children: [Text('Цена', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13)), const SizedBox(width: 10), SizedBox(width: 100, height: 36, child: TextField(controller: item.ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), textAlign: TextAlign.right, onChanged: (_) => setState(() {}), decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0), suffixText: '₽', fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)))), const Spacer(), Text('= ${_f(item.total)} ₽', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary))]),
          ]));
        })),
      ])),
      bottomNavigationBar: SafeArea(minimum: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: SizedBox(height: 54, child: OutlinedButton.icon(onPressed: _exporting ? null : _exportExcel, icon: const Icon(Icons.table_chart_outlined, size: 20), label: const Text('Excel')))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: SizedBox(height: 54, child: FilledButton.icon(onPressed: _exporting ? null : _exportPdf, icon: _exporting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.picture_as_pdf_outlined, size: 20), label: Text(_exporting ? 'Готовим...' : 'Скачать PDF')))),
      ])),
    );
  }
}

class _Item {
  final String name; final String unit; final double qty; final double meters; final int count; final double pieceLength; final String sectionLabel; final TextEditingController ctrl;
  
  _Item(this.name, this.unit, this.qty, this.meters, this.count, this.pieceLength, this.sectionLabel, String price) : ctrl = TextEditingController(text: price);
  
  double get price => double.tryParse(ctrl.text.trim().replaceAll(',', '.')) ?? 0;
  double get total => qty * price;

  String get actualSize {
    if (sectionLabel.isEmpty) return '-';
    if (count > 0 && pieceLength > 0) {
      return '$sectionLabel×${(pieceLength * 1000).toInt()} мм';
    }
    return '$sectionLabel×6000 мм';
  }

  String get exactSizeCount {
    if (count > 0 && pieceLength > 0) {
      return '$count шт × ${(pieceLength * 1000).toInt()} мм';
    }
    return '-';
  }

  String get cuttingPlan {
    if (sectionLabel.isEmpty) return '-';
    if (count == 0 || pieceLength <= 0) {
      return '${(meters / 6.0).ceil()} шт × 6000 мм';
    }
    if (pieceLength <= 3.0) return '$count шт × 3000 мм';
    if (pieceLength <= 4.0) return '$count шт × 4000 мм';
    if (pieceLength <= 6.0) return '$count шт × 6000 мм';
    
    double remainder = pieceLength - 6.0;
    if (remainder <= 3.0) return '$count шт × 6000 мм + $count шт × 3000 мм';
    return '$count шт × 6000 мм + $count шт × 4000 мм';
  }
}
