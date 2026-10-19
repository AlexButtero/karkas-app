enum LumberMaterialType {
  edged('Обрезная'),
  dryPlaned('Сухая строганая');
  final String label;
  const LumberMaterialType(this.label);
}

class LumberSection {
  final int widthMm;
  final int heightMm;
  final int actualWidthMm;
  final int actualHeightMm;
  final LumberMaterialType type;

  const LumberSection({
    required this.widthMm,
    required this.heightMm,
    required this.actualWidthMm,
    required this.actualHeightMm,
    required this.type,
  });

  double get actualAreaM2 => (actualWidthMm * actualHeightMm) / 1000000;
  String get label => '$widthMm×$heightMm';
  String get actualLabel => '$actualWidthMm×$actualHeightMm';

  String get displayLabel => type == LumberMaterialType.edged
      ? label
      : actualLabel;

  String get id => '${type.name}_${widthMm}x$heightMm';

  Map<String, dynamic> toJson() => {
        'w': widthMm,
        'h': heightMm,
        'aw': actualWidthMm,
        'ah': actualHeightMm,
        'type': type.name,
      };

  factory LumberSection.fromJson(Map<String, dynamic> j) => LumberSection(
        widthMm: j['w'] as int,
        heightMm: j['h'] as int,
        actualWidthMm: j['aw'] as int,
        actualHeightMm: j['ah'] as int,
        type: LumberMaterialType.values.byName(j['type'] as String),
      );

  @override
  bool operator ==(Object other) => other is LumberSection && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

const kEdgedSections = <LumberSection>[
  LumberSection(widthMm: 50, heightMm: 100, actualWidthMm: 50, actualHeightMm: 100, type: LumberMaterialType.edged),
  LumberSection(widthMm: 50, heightMm: 150, actualWidthMm: 50, actualHeightMm: 150, type: LumberMaterialType.edged),
  LumberSection(widthMm: 50, heightMm: 200, actualWidthMm: 50, actualHeightMm: 200, type: LumberMaterialType.edged),
  LumberSection(widthMm: 150, heightMm: 150, actualWidthMm: 150, actualHeightMm: 150, type: LumberMaterialType.edged),
];

const kDryPlanedSections = <LumberSection>[
  LumberSection(widthMm: 50, heightMm: 100, actualWidthMm: 45, actualHeightMm: 95, type: LumberMaterialType.dryPlaned),
  LumberSection(widthMm: 50, heightMm: 150, actualWidthMm: 45, actualHeightMm: 145, type: LumberMaterialType.dryPlaned),
  LumberSection(widthMm: 50, heightMm: 200, actualWidthMm: 45, actualHeightMm: 195, type: LumberMaterialType.dryPlaned),
];

List<LumberSection> sectionsFor(LumberMaterialType t) =>
    t == LumberMaterialType.edged ? kEdgedSections : kDryPlanedSections;

const kEdgedBattens = <LumberSection>[
  LumberSection(widthMm: 25, heightMm: 100, actualWidthMm: 25, actualHeightMm: 100, type: LumberMaterialType.edged),
  LumberSection(widthMm: 50, heightMm: 50, actualWidthMm: 50, actualHeightMm: 50, type: LumberMaterialType.edged),
];

const kDryPlanedBattens = <LumberSection>[
  LumberSection(widthMm: 25, heightMm: 100, actualWidthMm: 20, actualHeightMm: 95, type: LumberMaterialType.dryPlaned),
  LumberSection(widthMm: 50, heightMm: 50, actualWidthMm: 45, actualHeightMm: 45, type: LumberMaterialType.dryPlaned),
];

List<LumberSection> battensFor(LumberMaterialType t) =>
    t == LumberMaterialType.edged ? kEdgedBattens : kDryPlanedBattens;

const kEdgedCounterBattens = <LumberSection>[
  LumberSection(widthMm: 25, heightMm: 50, actualWidthMm: 25, actualHeightMm: 50, type: LumberMaterialType.edged),
];

const kDryPlanedCounterBattens = <LumberSection>[
  LumberSection(widthMm: 25, heightMm: 50, actualWidthMm: 20, actualHeightMm: 45, type: LumberMaterialType.dryPlaned),
];

List<LumberSection> counterBattensFor(LumberMaterialType t) =>
    t == LumberMaterialType.edged ? kEdgedCounterBattens : kDryPlanedCounterBattens;

const kBattenSpacingOptionsMm = <int>[350, 450, 500];
