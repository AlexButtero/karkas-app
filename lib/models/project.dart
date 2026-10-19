import 'dart:convert';
import 'frame_params.dart';
import 'house_dimensions.dart';

class Project {
  final int? id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final HouseDimensions dimensions;
  final FrameParams frameParams;
  final Map<String, double> prices;

  const Project({
    this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.dimensions,
    required this.frameParams,
    required this.prices,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'dimensions': jsonEncode(dimensions.toJson()),
        'frame_params': jsonEncode(frameParams.toJson()),
        'prices': jsonEncode(prices),
      };

  factory Project.fromMap(Map<String, dynamic> m) => Project(
        id: m['id'] as int?,
        name: m['name'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
        dimensions: HouseDimensions.fromJson(
            jsonDecode(m['dimensions'] as String) as Map<String, dynamic>),
        frameParams: FrameParams.fromJson(
            jsonDecode(m['frame_params'] as String) as Map<String, dynamic>),
        prices: (jsonDecode(m['prices'] as String) as Map)
            .map((k, v) => MapEntry(k as String, (v as num).toDouble())),
      );
}
