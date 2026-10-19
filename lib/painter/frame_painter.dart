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

  FramePainter({
    required this.dim,
    required this.params,
    required this.rotation,
    required this.pitch,
    required this.zoom,
    required this.pan,
    this.showRoof = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + pan;
    final scale = 16.0 * zoom;
    
    final sinPitch = math.sin(pitch);
    final cosPitch = math.cos(pitch);
    final cosYaw = math.cos(rotation);
    final sinYaw = math.sin(rotation);

    Offset project(double x, double y, double z) {
      final xr = x * cosYaw - z * sinYaw;
      final zr = x * sinYaw + z * cosYaw;
      return Offset(center.dx + xr * scale, center.dy + (-y + zr * sinPitch) * scale);
    }

    double depth(double x, double y, double z) {
      final zr = x * sinYaw + z * cosYaw;
      return y * sinPitch + zr * cosPitch;
    }

    final faces = <_Face>[];

    void addBox(double x, double y, double z, double w, double h, double d, Color base) {
      final x1 = x, x2 = x + w, y1 = y, y2 = y + h, z1 = z, z2 = z + d;
      final pts = [
        project(x1, y1, z1), project(x2, y1, z1), project(x2, y2, z1), project(x1, y2, z1),
        project(x1, y1, z2), project(x2, y1, z2), project(x2, y2, z2), project(x1, y2, z2),
      ];
      final fDefs = [
        ([0,1,2,3], base.withValues(alpha: 0.9)), ([4,5,6,7], base.withValues(alpha: 0.5)),
        ([0,3,7,4], base.withValues(alpha: 0.7)), ([1,2,6,5], base.withValues(alpha: 0.8)),
        ([3,2,6,7], base.withValues(alpha: 1.0)), ([0,1,5,4], base.withValues(alpha: 0.4)),
      ];
      final cx = (x1 + x2) / 2, cy = (y1 + y2) / 2, cz = (z1 + z2) / 2;
      final dep = depth(cx, cy, cz);
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
        ([0,1,5,4], base.withValues(alpha: 1.0)), ([2,3,7,6], base.withValues(alpha: 0.4)),
        ([0,3,7,4], base.withValues(alpha: 0.7)), ([1,2,6,5], base.withValues(alpha: 0.8)),
        ([0,1,2,3], base.withValues(alpha: 0.8)), ([4,5,6,7], base.withValues(alpha: 0.6)),
      ];
      final cx = x, cy = (yStart + yEnd) / 2, cz = (zStart + zEnd) / 2;
      final dep = depth(cx, cy, cz);
      for (final f in fDefs) {
        faces.add(_Face(f.$1.map((i) => pts[i]).toList(), f.$2, dep));
      }
    }

    final L = dim.lengthM;
    final W = dim.widthM;
    final H = dim.wallHeightM * dim.floors;
    final ridge = dim.ridgeRise;
    final spacing = dim.studSpacingMm / 1000;

    final sW = params.studs.actualWidthMm / 1000.0;
    final sH = params.studs.actualHeightMm / 1000.0;
    final pW = params.plates.actualWidthMm / 1000.0;
    final pH = params.plates.actualHeightMm / 1000.0;
    final jW = params.joists.actualWidthMm / 1000.0;
    final jH = params.joists.actualHeightMm / 1000.0;
    final rW = params.rafters.actualWidthMm / 1000.0;
    final rH = params.rafters.actualHeightMm / 1000.0;
    final bW = params.batten.actualWidthMm / 1000.0;
    final bH = params.batten.actualHeightMm / 1000.0;

    final wood = const Color(0xFFD1A77C);
    final woodDark = const Color(0xFFB89068);
    final studColor = const Color(0xFFE2B896);
    final joistColor = const Color(0xFFC4976D);
    final roofColor = const Color(0xFFB8855A);
    final battenColor = const Color(0xFFA67B52);
    final ridgeColor = const Color(0xFF9E6A40);

    void drawBottomPlate(double x, double z, double w, double d, {bool isCentral = false}) {
      final sec = params.bottomPlateType == BottomPlateType.solid ? 0.150 : params.plates.actualHeightMm / 1000.0;
      final mult = params.bottomPlateMultiplier;
      
      for (int i = 0; i < mult; i++) {
        final color = i % 2 == 0 ? wood : woodDark;
        if (isCentral) {
          addBox(x, i * sec, z, w, sec, d, color);
        } else {
          addBox(x, i * sec, z, w, sec, d, color);
        }
      }
    }

    bool isOpening(double pos, WallSide wall) {
      final wallOpenings = params.openings.where((o) => o.wall == wall).toList();
      if (wallOpenings.isEmpty) return false;
      double currentX = 0.0;
      final wallLen = (wall == WallSide.front || wall == WallSide.back) ? L : W;
      for (final op in wallOpenings) {
        final wM = op.widthMm / 1000.0;
        final gap = (wallLen - wallOpenings.fold<double>(0.0, (s, o) => s + (o.widthMm / 1000.0) * o.quantity)) / (wallOpenings.fold<int>(0, (s, o) => s + o.quantity) + 1);
        for (int i = 0; i < op.quantity; i++) {
          currentX += gap;
          if (pos >= currentX - 0.01 && pos <= currentX + wM + 0.01) return true;
          currentX += wM;
        }
      }
      return false;
    }

    void drawFraming(WallSide wall, double pos, Opening op) {
      final wM = op.widthMm / 1000.0;
      final hM = op.heightMm / 1000.0;
      final sillM = op.sillHeightMm / 1000.0;
      
      if (wall == WallSide.front || wall == WallSide.back) {
        final z = wall == WallSide.front ? 0.0 : W - pW;
        addBox(pos, sillM + hM, z, wM, pH, pW, studColor);
        if (op.type == OpeningType.window) {
          addBox(pos, sillM, z, wM, pH, pW, studColor);
        }
      } else {
        final x = wall == WallSide.left ? 0.0 : L - pW;
        addBox(x, sillM + hM, pos, pW, pH, wM, studColor);
        if (op.type == OpeningType.window) {
          addBox(x, sillM, pos, pW, pH, wM, studColor);
        }
      }
    }

    if (dim.isAFrame) {
      // ... (А-фрейм оставляем без изменений)
      drawBottomPlate(0.0, 0.0, L, pW);
      drawBottomPlate(0.0, W - pW, L, pW);
      drawBottomPlate(0.0, pW, pW, W - 2 * pW);
      drawBottomPlate(L - pW, pW, pW, W - 2 * pW);

      for (double x = pW * 2; x < L - pW; x += spacing) {
        addBox(x, pH, pW, jW, jH, W - 2 * pW, joistColor);
      }
      final midZ = W / 2;
      for (double x = pW; x <= L - 0.1; x += spacing) {
        addRafter(x, 0.0, 0.0, ridge, midZ, rW, rH, roofColor);
        addRafter(x, 0.0, W, ridge, midZ, rW, rH, roofColor);
      }
      addBox(0.0, ridge - rH / 2, midZ - rW / 2, L, rH, rW, ridgeColor);
    } else {
      // 1. Периметр и центральные балки
      drawBottomPlate(0.0, 0.0, L, pW);
      drawBottomPlate(0.0, W - pW, L, pW);
      drawBottomPlate(0.0, pW, pW, W - 2 * pW);
      drawBottomPlate(L - pW, pW, pW, W - 2 * pW);

      if (dim.centralBeamCount > 0) {
        for (int i = 1; i <= dim.centralBeamCount; i++) {
          final zPos = W * (i / (dim.centralBeamCount + 1)) - pW / 2;
          drawBottomPlate(pW, zPos, L - 2 * pW, pW, isCentral: true);
        }
      }

      // 2. Лаги пола
      for (double x = pW * 2; x < L - pW; x += spacing) {
        addBox(x, pH + 0.05, pW, jW, jH, W - 2 * pW, joistColor);
      }

      // 3. Стойки и проемы (Перед/Зад)
      for (final wall in [WallSide.front, WallSide.back]) {
        final z = wall == WallSide.front ? 0.0 : W - sW;
        for (double x = pW; x < L - 0.1; x += spacing) {
          if (!isOpening(x, wall)) addBox(x, pH, z, sW, H - pH * 2, sW, studColor);
        }
        final wallOpenings = params.openings.where((o) => o.wall == wall).toList();
        double currentX = 0.0;
        final gap = (L - wallOpenings.fold<double>(0.0, (s, o) => s + (o.widthMm / 1000.0) * o.quantity)) / (wallOpenings.fold<int>(0, (s, o) => s + o.quantity) + 1);
        for (final op in wallOpenings) {
          for (int i = 0; i < op.quantity; i++) {
            currentX += gap;
            drawFraming(wall, currentX, op);
            currentX += op.widthMm / 1000.0;
          }
        }
      }

      // 4. Стойки и проемы (Лево/Право)
      for (final wall in [WallSide.left, WallSide.right]) {
        final x = wall == WallSide.left ? 0.0 : L - sW;
        for (double z = pW * 2; z < W - 0.1; z += spacing) {
          if (!isOpening(z, wall)) addBox(x, pH, z, sW, H - pH * 2, sW, studColor);
        }
        final wallOpenings = params.openings.where((o) => o.wall == wall).toList();
        double currentZ = 0.0;
        final gap = (W - wallOpenings.fold<double>(0.0, (s, o) => s + (o.widthMm / 1000.0) * o.quantity)) / (wallOpenings.fold<int>(0, (s, o) => s + o.quantity) + 1);
        for (final op in wallOpenings) {
          for (int i = 0; i < op.quantity; i++) {
            currentZ += gap;
            drawFraming(wall, currentZ, op);
            currentZ += op.widthMm / 1000.0;
          }
        }
      }

      addBox(0.0, pH, 0.0, sW, H - pH * 2, sW, studColor);
      addBox(L - sW, pH, 0.0, sW, H - pH * 2, sW, studColor);
      addBox(0.0, pH, W - sW, sW, H - pH * 2, sW, studColor);
      addBox(L - sW, pH, W - sW, sW, H - pH * 2, sW, studColor);

      addBox(0.0, H - pH, 0.0, L, pH, pW, wood);
      addBox(0.0, H - pH, W - pW, L, pH, pW, wood);
      addBox(0.0, H - pH, pW, pW, pH, W - 2 * pW, wood);
      addBox(L - pW, H - pH, pW, pW, pH, W - 2 * pW, wood);

      if (showRoof) {
        final ridgeY = H + ridge;
        final midZ = W / 2;
        final pitchRad = dim.roofPitchDeg * math.pi / 180;
        final drop = dim.eaveOverhangM * math.tan(pitchRad);
        final yStart = H - drop;
        final zLeft = -dim.eaveOverhangM;
        final zRight = W + dim.eaveOverhangM;

        for (double x = pW; x < L - 0.1; x += spacing) {
          addRafter(x, yStart, zLeft, ridgeY, midZ, rW, rH, roofColor);
          addRafter(x, yStart, zRight, ridgeY, midZ, rW, rH, roofColor);
        }
        addBox(0.0, ridgeY - rH / 2, midZ - rW / 2, L, rH, rW, ridgeColor);

        final battenSpacingM = params.battenSpacingMm / 1000;
        final slopeLen = math.sqrt(math.pow(midZ - zLeft, 2) + math.pow(ridgeY - yStart, 2));
        final battenCount = (slopeLen / battenSpacingM).ceil() + 1;
        
        for (int i = 0; i < battenCount; i++) {
          final t = i / (battenCount - 1);
          final zL = zLeft + (midZ - zLeft) * t;
          final yL = yStart + (ridgeY - yStart) * t;
          final zR = zRight - (zRight - midZ) * t;
          final yR = yStart + (ridgeY - yStart) * t;
          
          addBox(0.0, yL + rH, zL - bW/2, L, bH, bW, battenColor);
          addBox(0.0, yR + rH, zR - bW/2, L, bH, bW, battenColor);
        }
      }
    }

    faces.sort((a, b) => b.depth.compareTo(a.depth));

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()..style = PaintingStyle.stroke..color = Colors.black.withValues(alpha: 0.15)..strokeWidth = 0.5;

    for (final f in faces) {
      final path = Path()..addPolygon(f.pts, true);
      canvas.drawPath(path, fillPaint..color = f.color);
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant FramePainter old) =>
      old.rotation != rotation || old.pitch != pitch || old.zoom != zoom ||
      old.pan != pan || old.showRoof != showRoof || old.dim != dim || old.params != params;
}

class _Face {
  final List<Offset> pts;
  final Color color;
  final double depth;
  _Face(this.pts, this.color, this.depth);
}
