import 'dart:math' as math;

class HouseDimensions {
  final double lengthM;
  final double widthM;
  final double wallHeightM;
  final double roofPitchDeg;
  final int floors;
  final double studSpacingMm;
  final double eaveOverhangM;
  final double groundClearanceM;
  final bool isAFrame;
  final int centralBeamCount; // <-- НОВОЕ: количество центральных балок

  const HouseDimensions({
    required this.lengthM,
    required this.widthM,
    required this.wallHeightM,
    required this.roofPitchDeg,
    required this.floors,
    required this.studSpacingMm,
    this.eaveOverhangM = 0.5,
    this.groundClearanceM = 0.15,
    this.isAFrame = false,
    this.centralBeamCount = 0,
  });

  double get footprintArea => lengthM * widthM;
  double get perimeter => 2 * (lengthM + widthM);
  
  double get ridgeRise => (widthM / 2) * math.tan(roofPitchDeg * math.pi / 180);
      
  double get totalHeight => isAFrame 
      ? groundClearanceM + ridgeRise 
      : groundClearanceM + wallHeightM * floors + ridgeRise;
      
  int get studsEstimate => isAFrame 
      ? ((lengthM / (studSpacingMm / 1000)).ceil() * 2) 
      : (perimeter * floors / (studSpacingMm / 1000)).ceil();

  Map<String, dynamic> toJson() => {
        'lengthM': lengthM,
        'widthM': widthM,
        'wallHeightM': wallHeightM,
        'roofPitchDeg': roofPitchDeg,
        'floors': floors,
        'studSpacingMm': studSpacingMm,
        'eaveOverhangM': eaveOverhangM,
        'groundClearanceM': groundClearanceM,
        'isAFrame': isAFrame,
        'centralBeamCount': centralBeamCount,
      };

  factory HouseDimensions.fromJson(Map<String, dynamic> j) => HouseDimensions(
        lengthM: (j['lengthM'] as num).toDouble(),
        widthM: (j['widthM'] as num).toDouble(),
        wallHeightM: (j['wallHeightM'] as num).toDouble(),
        roofPitchDeg: (j['roofPitchDeg'] as num).toDouble(),
        floors: j['floors'] as int,
        studSpacingMm: (j['studSpacingMm'] as num).toDouble(),
        eaveOverhangM: (j['eaveOverhangM'] as num?)?.toDouble() ?? 0.5,
        groundClearanceM: (j['groundClearanceM'] as num?)?.toDouble() ?? 0.15,
        isAFrame: j['isAFrame'] as bool? ?? false,
        centralBeamCount: j['centralBeamCount'] as int? ?? 0,
      );
}

enum InsulationType {
  mineralWool('Минвата'),
  pur('ППУ'),
  ecowool('Эковата');
  final String label;
  const InsulationType(this.label);
}

enum SheathingType {
  osb9('OSB-3 9 мм'),
  osb12('OSB-3 12 мм'),
  plywood12('Фанера 12 мм');
  final String label;
  const SheathingType(this.label);
}
