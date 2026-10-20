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
    required LumberSection crossBattens,
    required int wallSpacingMm,
    required int floorSpacingMm,
    required int roofSpacingMm,
    required int wallInsSpacingMm,
    required int roofInsSpacingMm,
    required List<Opening> openings,
    required InsulationType insulation,
    required double insulationThicknessMm,
    required BottomPlateType bottomPlateType,
    bool hasStonePlinth = false,
  }) {
    final perimeter = d.perimeter;
    final wallSpacing = wallSpacingMm / 1000;
    final floorSpacing = floorSpacingMm / 1000;
    final roofSpacing = roofSpacingMm / 1000;
    final slopeBase = math.sqrt(math.pow(d.widthM / 2, 2) + math.pow(d.ridgeRise, 2));
    final slopeWithOverhang = slopeBase + d.eaveOverhangM;

    final plateThickness = plates.actualWidthMm / 1000.0;
    final bottomPlateSec = bottomPlateType == BottomPlateType.solid ? kEdgedSections[3] : plates;
    final bottomPlateMultiplier = bottomPlateType == BottomPlateType.solid ? 1 : (bottomPlateType == BottomPlateType.pack3 ? 3 : 4);
    final bottomPlateThickness = bottomPlateSec.actualWidthMm / 1000.0;

    final centralBeamLength = d.centralBeamCount * (d.lengthM - 2 * bottomPlateThickness);
    final totalGrillageLength = perimeter + centralBeamLength;

    int rostverkNails = 0;
    double rostverkNailsKg = 0.0;
    if (bottomPlateType != BottomPlateType.solid) {
      final jointsCount = bottomPlateType == BottomPlateType.pack3 ? 2 : 3;
      final nailsPerMeter = ((1000 / 300).ceil() * 2) * jointsCount; 
      rostverkNails = (totalGrillageLength * nailsPerMeter).round();
      rostverkNailsKg = rostverkNails * 0.007;
    }

    final wallStCount = (perimeter * d.floors / wallSpacing).ceil();
    final wallStudMeters = wallStCount * d.wallHeightM;
    
    final wallInsRows = d.floors * (d.wallHeightM / (wallInsSpacingMm / 1000)).ceil();
    final wallInsMeters = wallInsRows * perimeter;

    final joistRows = (d.lengthM / floorSpacing).ceil();
    final joistLen = (d.widthM - bottomPlateThickness * 2);
    
    final joistMetersFloor1 = joistRows * joistLen;
    final joistMetersUpper = joistRows * joistLen * (d.floors - 1);
    final joistMetersAttic = joistRows * joistLen;

    final draftFloorArea = d.footprintArea * d.floors;

    final rafterRows = (d.lengthM / roofSpacing).ceil() + 1;
    final rafterMeters = rafterRows * 2 * slopeWithOverhang;

    final battenSpacingM = roofSpacingMm / 1000;
    final battenRows = (slopeWithOverhang / battenSpacingM).ceil() + 1;
    final battenMeters = battenRows * d.lengthM * 2;
    final counterBattenMeters = rafterRows * slopeWithOverhang * 2;

    final roofInsRows = (slopeWithOverhang / (roofInsSpacingMm / 1000)).ceil();
    final roofInsMeters = roofInsRows * d.lengthM * 2;

    final openingsArea = openings.fold<double>(0.0, (s, o) => s + o.areaM2);
    final wallsArea = math.max(0.0, perimeter * d.wallHeightM * d.floors - openingsArea);
    final roofArea = 2 * slopeWithOverhang * d.lengthM;
    final floorArea = d.footprintArea * d.floors;

    double framingMeters = 0;
    int framingCount = 0;
    for (final o in openings) {
      final headerLen = (o.widthMm + 100) / 1000;
      final jackLen = o.heightMm / 1000;
      final sillLen = (o.widthMm + 100) / 1000;
      framingMeters += (headerLen + 2 * jackLen + (o.type == OpeningType.window ? sillLen : 0)) * o.quantity;
      framingCount += (o.type == OpeningType.window ? 4 : 3) * o.quantity;
    }

    final sheathingArea = wallsArea + roofArea + floorArea;
    final osbSheets = (sheathingArea / 3.0).ceil();
    final insulationVolume = (wallsArea + roofArea + draftFloorArea) * insulationThicknessMm / 1000;
    final fastenersKg = sheathingArea * 0.3;

    return MaterialEstimate(
      lumber: [
        LumberItem('Стойки стен', studs, wallStudMeters, count: wallStCount, pieceLengthM: d.wallHeightM),
        LumberItem('Лаги пола 1-го этажа', joists, joistMetersFloor1, count: joistRows, pieceLengthM: d.widthM),
        if (d.floors > 1)
          LumberItem('Лаги перекрытий 2+ эт.', joists, joistMetersUpper, count: joistRows * (d.floors - 1), pieceLengthM: d.widthM),
        LumberItem('Балки чердака', joists, joistMetersAttic, count: joistRows, pieceLengthM: d.widthM),
        
        LumberItem('Стропила', rafters, rafterMeters, count: rafterRows * 2, pieceLengthM: slopeWithOverhang),
        LumberItem('Ростверк (нижняя)', bottomPlateSec, totalGrillageLength * bottomPlateMultiplier, count: (4 + d.centralBeamCount * 2) * bottomPlateMultiplier),
        LumberItem('Обвязка (верхняя)', plates, perimeter * d.floors, count: 4 * d.floors),
        
        LumberItem('Обрешетка стен (перекр. утеп.)', crossBattens, wallInsMeters),
        LumberItem('Обрешетка крыши (перекр. утеп.)', crossBattens, roofInsMeters),
        
        LumberItem('Обрешётка', batten, battenMeters),
        LumberItem('Контробрешётка', counterBatten, counterBattenMeters),
        
        if (openings.isNotEmpty) LumberItem('Обрамление проёмов', studs, framingMeters, count: framingCount),
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
