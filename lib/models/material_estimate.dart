import 'dart:math' as math;
import 'house_dimensions.dart';
import 'lumber_section.dart';
import 'opening.dart';
import 'frame_params.dart';

class LumberItem {
  final String name;
  final LumberSection section;
  final double meters;
  final int count;
  final double pieceLengthM;

  const LumberItem(this.name, this.section, this.meters, {this.count = 0, this.pieceLengthM = 0});
  double get volume => meters * section.actualAreaM2;
}

class MaterialEstimate {
  final List<LumberItem> lumber;
  final double wallsArea;
  final double roofArea;
  final double floorArea;
  final int osbSheets;
  final double insulationVolume;
  final InsulationType insulation;
  final double insulationThicknessMm;
  final double fastenersKg;
  final bool hasStonePlinth;
  final int rostverkNailsCount;
  final double rostverkNailsWeight;

  const MaterialEstimate({
    required this.lumber,
    required this.wallsArea,
    required this.roofArea,
    required this.floorArea,
    required this.osbSheets,
    required this.insulationVolume,
    required this.insulation,
    required this.insulationThicknessMm,
    required this.fastenersKg,
    this.hasStonePlinth = false,
    this.rostverkNailsCount = 0,
    this.rostverkNailsWeight = 0.0,
  });

  double get totalLumberMeters => lumber.fold(0.0, (s, e) => s + e.meters);
  double get totalLumberVolume => lumber.fold(0.0, (s, e) => s + e.volume);

  static MaterialEstimate fromDimensions(
    HouseDimensions d, {
    required LumberSection studs,
    required LumberSection plates,
    required LumberSection joists,
    required LumberSection rafters,
    required LumberSection batten,
    required LumberSection counterBatten,
    required int battenSpacingMm,
    required List<Opening> openings,
    required InsulationType insulation,
    required double insulationThicknessMm,
    required BottomPlateType bottomPlateType,
    bool hasStonePlinth = false,
  }) {
    final perimeter = d.perimeter;
    final spacingM = d.studSpacingMm / 1000;
    final slopeBase = math.sqrt(math.pow(d.widthM / 2, 2) + math.pow(d.ridgeRise, 2));
    final slopeWithOverhang = slopeBase + d.eaveOverhangM;

    final plateThickness = plates.actualWidthMm / 1000.0;
    
    final bottomPlateSec = bottomPlateType == BottomPlateType.solid ? kEdgedSections[3] : plates;
    final bottomPlateMultiplier = bottomPlateType == BottomPlateType.solid ? 1 : (bottomPlateType == BottomPlateType.pack3 ? 3 : 4);
    final bottomPlateThickness = bottomPlateSec.actualWidthMm / 1000.0;

    // Расчет длины ростверка (периметр + центральные балки)
    final centralBeamLength = d.centralBeamCount * (d.lengthM - 2 * bottomPlateThickness);
    final totalGrillageLength = perimeter + centralBeamLength;

    // Гвозди для пакета досок
    int rostverkNails = 0;
    double rostverkNailsKg = 0.0;
    if (bottomPlateType != BottomPlateType.solid) {
      final jointsCount = bottomPlateType == BottomPlateType.pack3 ? 2 : 3; // Кол-во швов
      final nailsPerMeter = ((1000 / 300).ceil() * 2) * jointsCount; 
      rostverkNails = (totalGrillageLength * nailsPerMeter).round();
      rostverkNailsKg = rostverkNails * 0.007;
    }

    double studMeters = 0;
    double topPlateMeters = 0;
    double joistMeters = 0;
    double rafterMeters = 0;
    double battenMeters = 0;
    double counterBattenMeters = 0;
    double wallsArea = 0;
    double roofArea = 0;
    double floorArea = 0;
    double framingMeters = 0;
    int framingCount = 0;

    if (d.isAFrame) {
      final rafterCount = ((d.lengthM / spacingM).ceil() + 1) * 2;
      rafterMeters = rafterCount * slopeBase;
      
      final frontStudsCount = (d.widthM / spacingM).ceil();
      final avgHeight = d.ridgeRise / 2;
      studMeters = frontStudsCount * avgHeight * 2;
      
      topPlateMeters = perimeter;
      
      joistMeters = ((d.lengthM - bottomPlateThickness * 2) / spacingM).ceil() * (d.widthM - bottomPlateThickness * 2);
      
      final battenSpacingM = battenSpacingMm / 1000;
      battenMeters = ((slopeBase / battenSpacingM).ceil() + 1) * d.lengthM * 2;
      counterBattenMeters = rafterMeters;

      wallsArea = d.widthM * d.ridgeRise;
      roofArea = 2 * slopeBase * d.lengthM;
      floorArea = d.footprintArea;
    } else {
      final studCount = (perimeter * d.floors / spacingM).ceil();
      studMeters = studCount * d.wallHeightM;
      
      topPlateMeters = perimeter * d.floors;
      
      final joistRows = (d.lengthM / spacingM).ceil();
      joistMeters = joistRows * (d.widthM - bottomPlateThickness * 2) * d.floors;
      
      final rafterRows = (d.lengthM / spacingM).ceil() + 1;
      rafterMeters = rafterRows * 2 * slopeWithOverhang;
      
      final battenSpacingM = battenSpacingMm / 1000;
      final battenRows = (slopeWithOverhang / battenSpacingM).ceil() + 1;
      battenMeters = battenRows * d.lengthM * 2;
      counterBattenMeters = rafterRows * slopeWithOverhang * 2;

      final openingsArea = openings.fold<double>(0.0, (s, o) => s + o.areaM2);
      wallsArea = math.max(0.0, perimeter * d.wallHeightM * d.floors - openingsArea);
      roofArea = 2 * slopeWithOverhang * d.lengthM;
      floorArea = d.footprintArea * d.floors;

      for (final o in openings) {
        final headerLen = (o.widthMm + 100) / 1000;
        final jackLen = o.heightMm / 1000;
        final sillLen = (o.widthMm + 100) / 1000;
        framingMeters += (headerLen + 2 * jackLen + (o.type == OpeningType.window ? sillLen : 0)) * o.quantity;
        framingCount += (o.type == OpeningType.window ? 4 : 3) * o.quantity;
      }
    }

    final sheathingArea = wallsArea + roofArea + floorArea;
    final osbSheets = (sheathingArea / 3.0).ceil();
    final insulationVolume = (wallsArea + roofArea) * insulationThicknessMm / 1000;
    final fastenersKg = sheathingArea * 0.3;

    return MaterialEstimate(
      lumber: [
        if (d.isAFrame) 
          LumberItem('Стропила (стены)', rafters, rafterMeters, count: ((d.lengthM / spacingM).ceil() + 1) * 2, pieceLengthM: slopeBase)
        else ...[
          LumberItem('Стойки', studs, studMeters, count: (perimeter * d.floors / spacingM).ceil(), pieceLengthM: d.wallHeightM),
          LumberItem('Стропила', rafters, rafterMeters, count: ((d.lengthM / spacingM).ceil() + 1) * 2, pieceLengthM: slopeWithOverhang),
        ],
        LumberItem('Ростверк (нижняя)', bottomPlateSec, totalGrillageLength * bottomPlateMultiplier, count: (4 + d.centralBeamCount * 2) * bottomPlateMultiplier, pieceLengthM: 0),
        LumberItem('Обвязка (верхняя)', plates, topPlateMeters, count: 4 * d.floors, pieceLengthM: 0),
        LumberItem('Лаги', joists, joistMeters, count: (d.lengthM / spacingM).ceil() * d.floors, pieceLengthM: d.widthM),
        LumberItem('Обрешётка', batten, battenMeters),
        LumberItem('Контробрешётка', counterBatten, counterBattenMeters),
        if (!d.isAFrame) LumberItem('Обрамление', studs, framingMeters, count: framingCount),
      ],
      wallsArea: wallsArea,
      roofArea: roofArea,
      floorArea: floorArea,
      osbSheets: osbSheets,
      insulationVolume: insulationVolume,
      insulation: insulation,
      insulationThicknessMm: insulationThicknessMm,
      fastenersKg: fastenersKg,
      hasStonePlinth: hasStonePlinth,
      rostverkNailsCount: rostverkNails,
      rostverkNailsWeight: rostverkNailsKg,
    );
  }
}
