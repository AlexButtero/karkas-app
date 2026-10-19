import 'house_dimensions.dart';
import 'lumber_section.dart';
import 'frame_params.dart';

class HouseStyle {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final List<String> tips;
  final double lengthM;
  final double widthM;
  final double wallHeightM;
  final double roofPitchDeg;
  final int floors;
  final double insulationMm;
  final SheathingType sheathing;
  final double eaveOverhangM;
  final double groundClearanceM;
  final String imagePath;
  final bool isAFrame;
  final bool hasStonePlinth;

  const HouseStyle({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.tips,
    required this.lengthM,
    required this.widthM,
    required this.wallHeightM,
    required this.roofPitchDeg,
    required this.floors,
    required this.insulationMm,
    required this.sheathing,
    this.eaveOverhangM = 0.5,
    this.groundClearanceM = 0.15,
    required this.imagePath,
    this.isAFrame = false,
    this.hasStonePlinth = false,
  });

  HouseDimensions get dimensions => HouseDimensions(
        lengthM: lengthM,
        widthM: widthM,
        wallHeightM: isAFrame ? 0 : wallHeightM,
        roofPitchDeg: roofPitchDeg,
        floors: floors,
        studSpacingMm: 600,
        eaveOverhangM: eaveOverhangM,
        groundClearanceM: groundClearanceM,
        isAFrame: isAFrame,
      );

  FrameParams get params => FrameParams(
        lumberType: LumberMaterialType.dryPlaned,
        studs: kDryPlanedSections[1],
        plates: kDryPlanedSections[1],
        rafters: kDryPlanedSections[1],
        joists: kDryPlanedSections[2],
        batten: kDryPlanedBattens[0],
        counterBatten: kDryPlanedCounterBattens[0],
        battenSpacingMm: 350,
        insulation: InsulationType.mineralWool,
        insulationThickness: insulationMm,
        sheathing: sheathing,
        openings: const [],
      );
}

const kHouseStyles = <HouseStyle>[
  HouseStyle(
    id: 'barnhouse', name: 'Барнхаус', tagline: 'Амбарный шик', description: 'Вытянутый объём, высокий фронтон и тёмный фасад.',
    tips: ['Соотношение сторон 1:2', 'Угол крыши 35–45°', 'Утепление 200 мм', 'Крыша без свесов (заподлицо)'],
    lengthM: 12, widthM: 6, wallHeightM: 3.2, roofPitchDeg: 40, floors: 1, insulationMm: 200,
    sheathing: SheathingType.osb12, eaveOverhangM: 0.0,
    imagePath: 'assets/styles/barnhouse.jpg',
  ),
  HouseStyle(
    id: 'scandi', name: 'Скандинавский', tagline: 'Свет и энергоэффективность', description: 'Максимум света, натуральные материалы, ставка на тепло.',
    tips: ['Утепление от 300 мм', 'Тройные стеклопакеты', 'Простая двускатная крыша', 'Светлое дерево на фасаде'],
    lengthM: 9, widthM: 7, wallHeightM: 2.8, roofPitchDeg: 30, floors: 1, insulationMm: 300,
    sheathing: SheathingType.osb9, eaveOverhangM: 0.5,
    imagePath: 'assets/styles/scandi.jpg',
  ),
  HouseStyle(
    id: 'chalet', name: 'Шале', tagline: 'Альпийский уют', description: 'Массивная крыша с широкими свесами, камень и дерево.',
    tips: ['Широкие свесы 700–1000 мм', 'Каменный цоколь', 'Часто с мансардой', 'Утепление 250 мм'],
    lengthM: 10, widthM: 8, wallHeightM: 2.9, roofPitchDeg: 35, floors: 2, insulationMm: 250,
    sheathing: SheathingType.osb12, eaveOverhangM: 0.8, groundClearanceM: 0.6,
    imagePath: 'assets/styles/chalet.jpg', hasStonePlinth: true,
  ),
  HouseStyle(
    id: 'aframe', name: 'A-Frame', tagline: 'Дом-шалаш', description: 'Крыша одновременно является стенами. Эффектно и компактно.',
    tips: ['Крутая крыша 45–60°', 'Антресольный второй свет', 'Идеально для дачи 30–60 м²', 'Фронтальное остекление'],
    lengthM: 7, widthM: 6, wallHeightM: 0, roofPitchDeg: 55, floors: 1, insulationMm: 250,
    sheathing: SheathingType.osb9, eaveOverhangM: 0.0,
    imagePath: 'assets/styles/aframe.jpg', isAFrame: true,
  ),
  HouseStyle(
    id: 'hitech', name: 'Хай-тек', tagline: 'Минимализм и стекло', description: 'Строгая геометрия, плоская крыша и умный дом.',
    tips: ['Плоская крыша', 'Панорамное остекление', 'Фасад: штукатурка или металл', 'Утепление 200 мм'],
    lengthM: 10, widthM: 8, wallHeightM: 3.0, roofPitchDeg: 5, floors: 1, insulationMm: 200,
    sheathing: SheathingType.osb12, eaveOverhangM: 0.0,
    imagePath: 'assets/styles/hitech.jpg',
  ),
];
