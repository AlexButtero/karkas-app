import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/house_dimensions.dart';
import '../models/frame_params.dart';
import '../models/opening.dart';

class FramePainter extends CustomPainter {
  final HouseDimensions dim;
  final FrameParams params;
  final double rotation;
  final double pitch;
  final double zoom;
  final Offset pan;
  final bool showRoof;
  final bool showWalls;
  final bool showFloors;
  final bool showGrillage;

  FramePainter({
    required this.dim,
    required this.params,
    required this.rotation,
    required this.pitch,
    required this.zoom,
    required this.pan,
    this.showRoof = true,
    this.showWalls = true,
    this.showFloors = true,
    this.showGrillage = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + pan;
    final scale = 16.0 * zoom;
    
    final sinPitch = math.sin(pitch);
    final cosPitch = math.cos(pitch);
    final cosYaw = math.cos(rotation);
    final sinYaw = math.sin(rotation);

    // Вектор направления света (светит сверху, слева, спереди)
    final lightDir = Vector3(-0.4, 0.8, -0.2).normalize();

    Offset project(double x, double y, double z) {
      final xr = x * cosYaw - z * sinYaw;
      final zr = x * sinYaw + z * cosYaw;
      return Offset(center.dx + xr * scale, center.dy + (-y + zr * sinPitch) * scale);
    }

    double depth(double x, double y, double z) {
      final zr = x * sinYaw + z * cosYaw;
      return y * sinPitch + zr * cosPitch;
    }

    // 1. РИСУЕМ СЕТКУ ПОЛА (Grid)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08) // Чуть ярче для контраста
      ..strokeWidth = 1.0 * zoom;
    
    for (int i = -10; i <= 10; i++) {
      final p1 = project(-10, -0.05, i.toDouble());
      final p2 = project(10, -0.05, i.toDouble());
      canvas.drawLine(p1, p2, gridPaint);
      
      final p3 = project(i.toDouble(), -0.05, -10);
      final p4 = project(i.toDouble(), -0.05, 10);
      canvas.drawLine(p3, p4, gridPaint);
    }

    final faces = <_Face>[];

    void addBox(double x, double y, double z, double w, double h, double d, Color base) {
      final x1 = x, x2 = x + w, y1 = y, y2 = y + h, z1 = z, z2 = z + d;
      final pts = [
        project(x1, y1, z1), project(x2, y1, z1), project(x2, y2, z1), project(x1, y2, z1), // передняя
        project(x1, y1, z2), project(x2, y1, z2), project(x2, y2, z2), project(x1, y2, z2), // задняя
      ];

      final fDefs = [
        ([0,1,2,3], _applyLight(base, Vector3(0, 0, -1), lightDir)), // Передняя
        ([4,5,6,7], _applyLight(base, Vector3(0, 0, 1), lightDir)),  // Задняя
        ([0,3,7,4], _applyLight(base, Vector3(-1, 0, 0), lightDir)), // Левая
        ([1,2,6,5], _applyLight(base, Vector3(1, 0, 0), lightDir)),  // Правая
        ([3,2,6,7], _applyLight(base, Vector3(0, 1, 0), lightDir)),  // Верхняя
        ([0,1,5,4], _applyLight(base, Vector3(0, -1, 0), lightDir)), // Нижняя
      ];

      final cx = (x1 + x2) / 2, cy = (y1 + y2) / 2, cz = (z1 + z2) / 2;
      // Добавляем микро-смещение, чтобы избежать ряби (Z-fighting)
      final dep = depth(cx, cy, cz) + (w * h * d) * 0.001;

      for (final f in fDefs) {
        faces.add(_Face(f.$1.map((i) => pts[i]).toList(), f.$2, dep));
      }
    }

    void addRafter(double x, double yStart, double zStart, double yEnd, double zEnd, double w, double h, Color base) {
      final dy = yEnd - yStart;
      final dz = zEnd - zStart;
      final len = math.sqrt(dy * dy + dz * dz);
      if (len == 0) return;
      final ny = dy / len, nz = dz / len;
      final py = -nz, pz = ny;
      final hw = w / 2;
      final hh = h / 2;
      final s1 = (x - hw, yStart + hh * py, zStart + hh * pz);
      final s2 = (x + hw, yStart + hh * py, zStart + hh * pz);
      final s3 = (x + hw, yStart - hh * py, zStart - hh * pz);
      final s4 = (x - hw, yStart - hh * py, zStart - hh * pz);
      final e1 = (x - hw, yEnd + hh * py, zEnd + hh * pz);
      final e2 = (x + hw, yEnd + hh * py, zEnd + hh * pz);
      final e3 = (x + hw, yEnd - hh * py, zEnd - hh * pz);
      final e4 = (x - hw, yEnd - hh * py, zEnd - hh * pz);
      final pts = [
        project(s1.$1, s1.$2, s1.$3), project(s2.$1, s2.$2, s2.$3), project(s3.$1, s3.$2, s3.$3), project(s4.$1, s4.$2, s4.$3),
        project(e1.$1, e1.$2, e1.$3), project(e2.$1, e2.$2, e2.$3), project(e3.$1, e3.$2, e3.$3), project(e4.$1, e4.$2, e4.$3),
      ];
      
      final fDefs = [
        ([0,1,5,4], _applyLight(base, Vector3(0, py, pz), lightDir)), // Верх
        ([2,3,7,6], _applyLight(base, Vector3(0, -py, -pz), lightDir)), // Низ
        ([0,3,7,4], _applyLight(base, Vector3(-1, 0, 0), lightDir)), // Левый бок
        ([1,2,6,5], _applyLight(base, Vector3(1, 0, 0), lightDir)), // Правый бок
        ([0,1,2,3], _applyLight(base, Vector3(0, -ny, -nz), lightDir)), // Торец
        ([4,5,6,7], _applyLight(base, Vector3(0, ny, nz), lightDir)), // Торец
      ];
      
      final cx = x, cy = (yStart + yEnd) / 2, cz = (zStart + zEnd) / 2;
      final dep = depth(cx, cy, cz) + 0.001;

      for (final f in fDefs) {
        faces.add(_Face(f.$1.map((i) => pts[i]).toList(), f.$2, dep));
      }
    }

    final L = dim.lengthM;
    final W = dim.widthM;
    final H = dim.wallHeightM;
    final totalH = H * dim.floors;
    final ridge = dim.ridgeRise;
    
    final wallSpacing = params.wallStudSpacingMm / 1000;
    final floorSpacing = params.floorJoistSpacingMm / 1000;
    final roofSpacing = params.roofRafterSpacingMm / 1000;
    final wallInsSpacing = params.wallCrossInsulationSpacingMm / 1000;
    final roofInsSpacing = params.roofCrossInsulationSpacingMm / 1000;

    final sW = params.studs.actualWidthMm / 1000.0;
    final pH = params.plates.actualHeightMm / 1000.0;
    final pW = params.plates.actualWidthMm / 1000.0;
    final jW = params.joists.actualWidthMm / 1000.0;
    final jH = params.joists.actualHeightMm / 1000.0;
    final rW = params.rafters.actualWidthMm / 1000.0;
    final rH = params.rafters.actualHeightMm / 1000.0;
    final bW = params.batten.actualWidthMm / 1000.0;
    final bH = params.batten.actualHeightMm / 1000.0;
    final cW = params.crossBattens.actualWidthMm / 1000.0;
    final cH = params.crossBattens.actualHeightMm / 1000.0;

    // Естественные, чуть более светлые цвета дерева
    final wood = const Color(0xFFD4A373);       
    final woodDark = const Color(0xFFB58354);   
    final studColor = const Color(0xFFE0B588);  
    final joistColor = const Color(0xFFCCA170); 
    final roofColor = const Color(0xFFB88B60);  
    final battenColor = const Color(0xFFC49565);
    final ridgeColor = const Color(0xFF9E6A40); 
    final insColor = const Color(0xFFF0D080);   

    final beamWidth = params.bottomPlateType == BottomPlateType.solid ? 0.150 : (params.plates.actualWidthMm / 1000.0 * params.bottomPlateMultiplier);

    if (showGrillage) {
      void drawBeam(double x, double z, double len, double wid, {required bool alignX}) {
        if (params.bottomPlateType == BottomPlateType.solid) {
          addBox(x, 0, z, alignX ? len : wid, 0.150, alignX ? wid : len, wood);
        } else {
          final bw = params.plates.actualWidthMm / 1000.0;
          final bh = params.plates.actualHeightMm / 1000.0;
          final count = params.bottomPlateMultiplier;
          
          for (int i = 0; i < count; i++) {
            final color = i % 2 == 0 ? wood : woodDark;
            if (alignX) {
              addBox(x, 0, z + i * bw, len, bh, bw, color);
            } else {
              addBox(x + i * bw, 0, z, bw, bh, len, color);
            }
          }
        }
      }

      drawBeam(0.0, 0.0, L, beamWidth, alignX: true);
      drawBeam(0.0, W - beamWidth, L, beamWidth, alignX: true);
      drawBeam(0.0, beamWidth, W - 2 * beamWidth, beamWidth, alignX: false);
      drawBeam(L - beamWidth, beamWidth, W - 2 * beamWidth, beamWidth, alignX: false);

      if (dim.centralBeamCount > 0) {
        for (int i = 1; i <= dim.centralBeamCount; i++) {
          final zPos = W * (i / (dim.centralBeamCount + 1)) - beamWidth / 2;
          drawBeam(beamWidth, zPos, L - 2 * beamWidth, beamWidth, alignX: true);
        }
      }
    }

    if (showFloors) {
      for (int f = 0; f < dim.floors; f++) {
        final yPos = f * H + pH;
        for (double x = beamWidth * 2; x < L - beamWidth; x += floorSpacing) {
          addBox(x, yPos, beamWidth, jW, jH, W - 2 * beamWidth, joistColor);
        }
      }
    }

    if (showWalls) {
      for (int f = 0; f < dim.floors; f++) {
        final yBase = f * H;
        for (double x = pW; x < L - 0.1; x += wallSpacing) {
          addBox(x, yBase + pH, 0.0, sW, H - pH * 2, sW, studColor);
          addBox(x, yBase + pH, W - sW, sW, H - pH * 2, sW, studColor);
        }
        for (double z = pW * 2; z < W - 0.1; z += wallSpacing) {
          addBox(0.0, yBase + pH, z, sW, H - pH * 2, sW, studColor);
          addBox(L - sW, yBase + pH, z, sW, H - pH * 2, sW, studColor);
        }
        if (f == 0) {
          for (double y = pH + wallInsSpacing; y < H - pH; y += wallInsSpacing) {
            addBox(0, yBase + y, -cW, L, cH, cW, insColor);
            addBox(0, yBase + y, W, L, cH, cW, insColor);
          }
        }
      }
    }

    if (showRoof && showWalls) {
      final ridgeY = totalH + ridge;
      final midZ = W / 2;
      final pitchRad = dim.roofPitchDeg * math.pi / 180;
      final drop = dim.eaveOverhangM * math.tan(pitchRad);
      final yStart = totalH - drop;
      final zLeft = -dim.eaveOverhangM;
      final zRight = W + dim.eaveOverhangM;

      for (double x = pW; x < L - 0.1; x += roofSpacing) {
        addRafter(x, yStart, zLeft, ridgeY, midZ, rW, rH, roofColor);
        addRafter(x, yStart, zRight, ridgeY, midZ, rW, rH, roofColor);
      }
      addBox(0.0, ridgeY - rH / 2, midZ - rW / 2, L, rH, rW, ridgeColor);

      final slopeLen = math.sqrt(math.pow(midZ - zLeft, 2) + math.pow(ridgeY - yStart, 2));
      final roofInsCount = (slopeLen / roofInsSpacing).ceil();
      
      for (int i = 0; i < roofInsCount; i++) {
        final t = i / (roofInsCount > 1 ? roofInsCount - 1 : 1);
        final zL = zLeft + (midZ - zLeft) * t;
        final yL = yStart + (ridgeY - yStart) * t;
        final zR = zRight - (zRight - midZ) * t;
        final yR = yStart + (ridgeY - yStart) * t;
        
        addBox(0.0, yL - cH, zL, L, cH, cW, insColor);
        addBox(0.0, yR - cH, zR, L, cH, cW, insColor);
      }
    }

    // 3. СОРТИРОВКА И ОТРИСОВКА
    // Сортируем строго по глубине, чтобы передние грани рисовались поверх задних
    faces.sort((a, b) => b.depth.compareTo(a.depth));

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withValues(alpha: 0.15) // Мягкая обводка, не делает модель черной
      ..strokeWidth = 0.5;

    for (final f in faces) {
      final path = Path()..addPolygon(f.pts, true);
      
      final rect = _getBounds(f.pts);
      if (rect != null && rect.width > 2 && rect.height > 2) {
        final isHorizontal = rect.width > rect.height;
        final gradient = ui.Gradient.linear(
          isHorizontal ? rect.centerLeft : rect.topCenter,
          isHorizontal ? rect.centerRight : rect.bottomCenter,
          [
            f.color.withValues(alpha: 0.8),
            f.color,
            f.color.withValues(alpha: 0.8),
            f.color,
          ],
          [0.0, 0.3, 0.7, 1.0]
        );
        fillPaint.shader = gradient;
      } else {
        fillPaint.shader = null;
        fillPaint.color = f.color;
      }
      
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }
  }

  // Мягкое освещение (чтобы не было черных провалов)
  Color _applyLight(Color base, Vector3 normal, Vector3 lightDir) {
    final dot = normal.dot(lightDir);
    // Базовый свет 0.6 (60% яркости) + направленный
    final intensity = 0.6 + 0.4 * math.max(0.0, dot);
    
    final r = (base.red * intensity).clamp(0, 255).toInt();
    final g = (base.green * intensity).clamp(0, 255).toInt();
    final b = (base.blue * intensity).clamp(0, 255).toInt();
    
    return Color.fromARGB(255, r, g, b);
  }

  Rect? _getBounds(List<Offset> pts) {
    if (pts.isEmpty) return null;
    double minX = pts[0].dx, maxX = pts[0].dx;
    double minY = pts[0].dy, maxY = pts[0].dy;
    for (var p in pts) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool shouldRepaint(covariant FramePainter old) =>
      old.rotation != rotation || old.pitch != pitch || old.zoom != zoom ||
      old.pan != pan || old.showRoof != showRoof || old.showWalls != showWalls || 
      old.showFloors != showFloors || old.showGrillage != showGrillage ||
      old.dim != dim || old.params != params;
}

class Vector3 {
  final double x, y, z;
  Vector3(this.x, this.y, this.z);
  
  Vector3 normalize() {
    final len = math.sqrt(x*x + y*y + z*z);
    if (len == 0) return this;
    return Vector3(x/len, y/len, z/len);
  }
  
  double dot(Vector3 other) => x*other.x + y*other.y + z*other.z;
}

class _Face {
  final List<Offset> pts;
  final Color color;
  final double depth;
  _Face(this.pts, this.color, this.depth);
}
