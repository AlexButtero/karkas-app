import 'lumber_section.dart';
import 'house_dimensions.dart';
import 'opening.dart';

enum BottomPlateType {
  solid('Брус 150×150'),
  pack3('Пакет 3 доски'),
  pack4('Пакет 4 доски');
  final String label;
  const BottomPlateType(this.label);
}

class FrameParams {
  final LumberMaterialType lumberType;
  final LumberSection studs;
  final LumberSection plates;
  final LumberSection joists;
  final LumberSection rafters;
  final LumberSection batten;
  final LumberSection counterBatten;
  
  // Шаги каркаса и утепления
  final int wallStudSpacingMm;
  final int floorJoistSpacingMm;
  final int roofRafterSpacingMm;
  final int wallCrossInsulationSpacingMm;
  final int roofCrossInsulationSpacingMm;
  
  final List<Opening> openings;
  final InsulationType insulation;
  final double insulationThickness;
  final SheathingType sheathing;
  final BottomPlateType bottomPlateType;

  FrameParams({
    this.lumberType = LumberMaterialType.edged,
    LumberSection? studs,
    LumberSection? plates,
    LumberSection? joists,
    LumberSection? rafters,
    LumberSection? batten,
    LumberSection? counterBatten,
    this.wallStudSpacingMm = 600,
    this.floorJoistSpacingMm = 600,
    this.roofRafterSpacingMm = 600,
    this.wallCrossInsulationSpacingMm = 400,
    this.roofCrossInsulationSpacingMm = 400,
    this.openings = const [],
    this.insulation = InsulationType.mineralWool,
    this.insulationThickness = 150,
    this.sheathing = SheathingType.osb9,
    this.bottomPlateType = BottomPlateType.solid,
  })  : studs = studs ?? kEdgedSections[1],
        plates = plates ?? kEdgedSections[1],
        joists = joists ?? kEdgedSections[2],
        rafters = rafters ?? kEdgedSections[1],
        batten = batten ?? kEdgedBattens[0],
        counterBatten = counterBatten ?? kEdgedCounterBattens[0];

  Map<String, dynamic> toJson() => {
        'lumberType': lumberType.name,
        'studs': studs.toJson(),
        'plates': plates.toJson(),
        'joists': joists.toJson(),
        'rafters': rafters.toJson(),
        'batten': batten.toJson(),
        'counterBatten': counterBatten.toJson(),
        'wallStudSpacingMm': wallStudSpacingMm,
        'floorJoistSpacingMm': floorJoistSpacingMm,
        'roofRafterSpacingMm': roofRafterSpacingMm,
        'wallCrossInsulationSpacingMm': wallCrossInsulationSpacingMm,
        'roofCrossInsulationSpacingMm': roofCrossInsulationSpacingMm,
        'openings': openings.map((o) => o.toJson()).toList(),
        'insulation': insulation.name,
        'insulationThickness': insulationThickness,
        'sheathing': sheathing.name,
        'bottomPlateType': bottomPlateType.name,
      };

  factory FrameParams.fromJson(Map<String, dynamic> j) {
    LumberSection parseSection(dynamic raw) {
      if (raw is Map<String, dynamic>) return LumberSection.fromJson(raw);
      return kEdgedSections[1];
    }

    return FrameParams(
      lumberType: j['lumberType'] != null ? LumberMaterialType.values.byName(j['lumberType'] as String) : LumberMaterialType.edged,
      studs: parseSection(j['studs']),
      plates: parseSection(j['plates']),
      joists: parseSection(j['joists']),
      rafters: parseSection(j['rafters']),
      batten: j['batten'] != null ? LumberSection.fromJson(j['batten'] as Map<String, dynamic>) : kEdgedBattens[0],
      counterBatten: j['counterBatten'] != null ? LumberSection.fromJson(j['counterBatten'] as Map<String, dynamic>) : kEdgedCounterBattens[0],
      wallStudSpacingMm: j['wallStudSpacingMm'] as int? ?? 600,
      floorJoistSpacingMm: j['floorJoistSpacingMm'] as int? ?? 600,
      roofRafterSpacingMm: j['roofRafterSpacingMm'] as int? ?? 600,
      wallCrossInsulationSpacingMm: j['wallCrossInsulationSpacingMm'] as int? ?? 400,
      roofCrossInsulationSpacingMm: j['roofCrossInsulationSpacingMm'] as int? ?? 400,
      openings: (j['openings'] as List).map((o) => Opening.fromJson(o as Map<String, dynamic>)).toList(),
      insulation: InsulationType.values.byName(j['insulation'] as String),
      insulationThickness: (j['insulationThickness'] as num).toDouble(),
      sheathing: SheathingType.values.byName(j['sheathing'] as String),
      bottomPlateType: j['bottomPlateType'] != null ? BottomPlateType.values.byName(j['bottomPlateType'] as String) : BottomPlateType.solid,
    );
  }
}
