enum OpeningType {
  window('Окно'),
  door('Дверь');
  final String label;
  const OpeningType(this.label);
}

enum WallSide {
  front('Передняя'),
  back('Задняя'),
  left('Левая'),
  right('Правая');
  final String label;
  const WallSide(this.label);
}

class Opening {
  final String id;
  final OpeningType type;
  final double widthMm;
  final double heightMm;
  final double sillHeightMm;
  final int quantity;
  final WallSide wall;

  const Opening({
    required this.id,
    required this.type,
    required this.widthMm,
    required this.heightMm,
    required this.sillHeightMm,
    required this.quantity,
    required this.wall,
  });

  double get areaM2 => (widthMm * heightMm) / 1000000 * quantity;

  String get displayLabel {
    final base = '${type.label} ${widthMm.toInt()} × ${heightMm.toInt()} мм';
    return quantity > 1 ? '$base · $quantity шт' : base;
  }

  String get positionLabel => type == OpeningType.door
      ? 'Напольный'
      : 'От пола ${sillHeightMm.toInt()} мм';

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'widthMm': widthMm,
        'heightMm': heightMm,
        'sillHeightMm': sillHeightMm,
        'quantity': quantity,
        'wall': wall.name,
      };

  factory Opening.fromJson(Map<String, dynamic> j) => Opening(
        id: j['id'] as String,
        type: OpeningType.values.byName(j['type'] as String),
        widthMm: (j['widthMm'] as num).toDouble(),
        heightMm: (j['heightMm'] as num).toDouble(),
        sillHeightMm: (j['sillHeightMm'] as num).toDouble(),
        quantity: j['quantity'] as int,
        wall: WallSide.values.byName(j['wall'] as String),
      );

  static List<Opening> defaults() => [
        const Opening(
          id: 'w1',
          type: OpeningType.window,
          widthMm: 1500,
          heightMm: 1500,
          sillHeightMm: 900,
          quantity: 4,
          wall: WallSide.front,
        ),
        const Opening(
          id: 'd1',
          type: OpeningType.door,
          widthMm: 900,
          heightMm: 2100,
          sillHeightMm: 0,
          quantity: 1,
          wall: WallSide.front,
        ),
      ];

  static String generateId() => 'op_${DateTime.now().microsecondsSinceEpoch}';
}
