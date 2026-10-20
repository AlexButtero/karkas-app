import 'dart:math' as math;
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

    // Свет направлен сверху-слева-спереди
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

    // Сетка пола (ярче)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0 * math.sqrt(zoom);
    
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
      
      final p0 = project(x1, y1, z1); final p1 = project(x2, y1, z1);
      final p2 = project(x2, y2, z1); final p3 = project(x1, y2, z1);
      final p4 = project(x1, y1, z2); final p5 = project(x2, y1, z2);
      final p6 = project(x2, y2, z2); final p7 = project(x1, y2, z2);

      final defs = [
        ([p0, p1, p2, p3], Vector3(0, 0, -1), base), // Перед
        ([p5, p4, p7, p6], Vector3(0, 0, 1), base),  // Зад
        ([p4, p0, p3, p7], Vector3(-1, 0, 0), base), // Лево
        ([p1, p5, p6, p2], Vector3(1, 0, 0), base),  // Право
        ([p3, p2, p6, p7], Vector3(0, 1, 0), base),  // Верх
        ([p4, p5, p1, p0], Vector3(0, -1, 0), base), // Низ
      ];

      final cx = (x1 + x2) / 2, cy = (y1 + y2) / 2, cz = (z1 + z2) / 2;
      final dep = depth(cx, cy, cz) + (w * h * d) * 0.001; 

      for (final f in defs) {
        if (!_isVisible(f.$1)) continue; 
        final litColor = _applyLight(f.$3, f.$2, lightDir);
        faces.add(_Face(f.$1, litColor, dep));
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
      
      final ps1 = project(s1.$1, s1.$2, s1.$3); final ps2 = project(s2.$1, s2.$2, s2.$3);
      final ps3 = project(s3.$1, s3.$2, s3.$3); final ps4 = project(s4.$1, s4.$2, s4.$3);
      final pe1 = project(e1.$1, e1.$2, e1.$3); final pe2 = project(e2.$1, e2.$2, e2.$3);
      final pe3 = project(e3.$1, e3.$2, e3.$3); final pe4 = project(e4.$1, e4.$2, e4.$3);

      final defs = [
        ([ps1, ps2, pe2, pe1], Vector3(0, py, pz), base),
        ([ps3, pe3, pe4, ps4], Vector3(0, -py, -pz), base),
        ([ps1, ps4, pe4, pe1], Vector3(-1, 0, 0), base),
        ([ps2, pe2, pe3, ps3], Vector3(1, 0, 0), base),
        ([ps1, pe1, pe3, ps3], Vector3(0, -ny, -nz), base),
        ([ps2, ps4, pe4, pe2], Vector3(0, ny, nz), base),
      ];
      
      final cx = x, cy = (yStart + yEnd) / 2, cz = (zStart + zEnd) / 2;
      final dep = depth(cx, cy, cz) + 0.001;

      for (final f in defs) {
        if (!_isVisible(f.$1)) continue;
        final litColor = _applyLight(f.$3, f.$2, lightDir);
        faces.add(_Face(f.$1, litColor, dep));
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
    final cW = params.crossBattens.actualWidthMm / 1000.0;
    final cH = params.crossBattens.actualHeightMm / 1000.0;

    // Яркие цвета
    final woodPass = const Color(0xFFF0C080); // Сквозная доска
    final woodButt = const Color(0xFFC08050); // Упирающаяся доска
    final studColor = const Color(0xFFE8C090);  
    final joistColor = const Color(0xFFD8A870); 
    final roofColor = const Color(0xFFC89868);  
    final ridgeColor = const Color(0xFF9E6A40); 
    final insColor = const Color(0xFFFFE080);   

    final beamWidth = params.bottomPlateType == BottomPlateType.solid 
        ? 0.150 
        : (params.plates.actualHeightMm / 1000.0);

    if (showGrillage) {
      if (params.bottomPlateType == BottomPlateType.solid) {
        addBox(0.0, 0.0, 0.0, L, 0.150, beamWidth, woodPass);
        addBox(0.0, 0.0, W - beamWidth, L, 0.150, beamWidth, woodPass);
        addBox(0.0, 0.0, beamWidth, beamWidth, 0.150, W - 2 * beamWidth, woodPass);
        addBox(L - beamWidth, 0.0, beamWidth, beamWidth, 0.150, W - 2 * beamWidth, woodPass);
      } else {
        final bw = params.plates.actualWidthMm / 1000.0; 
        final bh = params.plates.actualHeightMm / 1000.0; 
        final count = params.bottomPlateMultiplier;
        
        for (int i = 0; i < count; i++) {
          final isXPass = (i % 2 == 0); 
          final zOffset = i * bw; 
          
          // ВАЖНО: Доски стоят на ребре (h=bh, d=bw)
          if (isXPass) {
            // Слой X (Передняя/Задняя) проходят насквозь (Светлые)
            addBox(0.0, 0.0, zOffset, L, bh, bw, woodPass); 
            addBox(0.0, 0.0, W - bw - zOffset, L, bh, bw, woodPass);
            
            // Слой Z (Левая/Правая) упираются (Темные), обрезаны по толщине
            addBox(0.0, 0.0, bw + zOffset, bw, bh, W - 2 * bw, woodButt);
            addBox(L - bw, 0.0, bw + zOffset, bw, bh, W - 2 * bw, woodButt);
          } else {
            // Слой Z (Левая/Правая) проходят насквозь (Светлые)
            addBox(0.0, 0.0, zOffset, bw, bh, W, woodPass);
            addBox(L - bw, 0.0, zOffset, bw, bh, W, woodPass);
            
            // Слой X (Передняя/Задняя) упираются (Темные), обрезаны по толщине
            addBox(bw, 0.0, zOffset, L - 2 * bw, bh, bw, woodButt);
            addBox(bw, 0.0, W - bw - zOffset, L - 2 * bw, bh, bw, woodButt);
          }
        }
      }

      // Центральные балки
      if (dim.centralBeamCount > 0) {
        for (int i = 1; i <= dim.centralBeamCount; i++) {
          final zPos = W * (i / (dim.centralBeamCount + 1)) - beamWidth / 2;
          if (params.bottomPlateType == BottomPlateType.solid) {
             addBox(beamWidth, 0.0, zPos, L - 2 * beamWidth, 0.150, beamWidth, woodPass);
          } else {
             final bw = params.plates.actualWidthMm / 1000.0;
             final bh = params.plates.actualHeightMm / 1000.0;
             final count = params.bottomPlateMultiplier;
             for (int j = 0; j < count; j++) {
               final color = j % 2 == 0 ? woodPass : woodButt;
               final zOff = j * bw;
               addBox(beamWidth, 0.0, zPos + zOff, L - 2 * beamWidth, bh, bw, color);
             }
          }
        }
      }
    }

    if (showFloors) {
      for (int f = 0; f < dim.floors; f++) {
        final yPos = f * H + beamWidth;
        for (double x = beamWidth * 2; x < L - beamWidth; x += floorSpacing) {
          // Лаги тоже на ребре (h=jH, d=jW)
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

    faces.sort((a, b) => b.depth.compareTo(a.depth));

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Сплошная, четкая обводка
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withValues(alpha: 0.8)
      ..strokeWidth = 1.2 * math.sqrt(zoom) 
      ..isAntiAlias = true;

    for (final f in faces) {
      final path = Path()..addPolygon(f.pts, true);
      fillPaint.color = f.color;
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }
  }

  bool _isVisible(List<Offset> pts) {
    if (pts.length < 3) return false;
    double area = 0.0;
    for (int i = 0; i < pts.length; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % pts.length];
      area += (p1.dx * p2.dy) - (p2.dx * p1.dy);
    }
    return area > 0;
  }

  // Яркое освещение
  Color _applyLight(Color base, Vector3 normal, Vector3 lightDir) {
    final dot = normal.dot(lightDir);
    final intensity = 0.8 + 0.2 * math.max(0.0, dot);
    
    final r = (base.red * intensity).clamp(0, 255).toInt();
    final g = (base.green * intensity).clamp(0, 255).toInt();
    final b = (base.blue * intensity).clamp(0, 255).toInt();
    
    return Color.fromARGB(255, r, g, b);
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
