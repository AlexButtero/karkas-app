import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/house_dimensions.dart';
import '../models/frame_params.dart';

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
      return Offset(
        center.dx + xr * scale,
        center.dy + (-y + zr * sinPitch) * scale,
      );
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
        ([0,1,2,3], base.withValues(alpha: 0.9)),
        ([4,5,6,7], base.withValues(alpha: 0.5)),
        ([0,3,7,4], base.withValues(alpha: 0.7)),
        ([1,2,6,5], base.withValues(alpha: 0.8)),
        ([3,2,6,7], base.withValues(alpha: 1.0)),
        ([0,1,5,4], base.withValues(alpha: 0.4)),
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
        ([0,1,5,4], base.withValues(alpha: 1.0)),
        ([2,3,7,6], base.withValues(alpha: 0.4)),
        ([0,3,7,4], base.withValues(alpha: 0.7)),
        ([1,2,6,5], base.withValues(alpha: 0.8)),
        ([0,1,2,3], base.withValues(alpha: 0.8)),
        ([4,5,6,7], base.withValues(alpha: 0.6)),
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

    final wood = const Color(0xFFD1A77C);
    final studColor = const Color(0xFFE2B896);
    final joistColor = const Color(0xFFC4976D);
    final roofColor = const Color(0xFFB8855A);
    final ridgeColor = const Color(0xFF9E6A40);

    if (dim.isAFrame) {
      // Нижняя обвязка
      addBox(0, 0, 0, L, pH, pW, wood);
      addBox(0, 0, W - pW, L, pH, pW, wood);
      addBox(0, 0, pW, pW, pH, W - 2 * pW, wood);
      addBox(L - pW, 0, pW, pW, pH, W - 2 * pW, wood);
      
      // Лаги пола
      for (double x = pW * 2; x < L - pW; x += spacing) {
        addBox(x, pH, pW, jW, jH, W - 2 * pW, joistColor);
      }

      final midZ = W / 2;
      for (double x = pW; x <= L - 0.1; x += spacing) {
        addRafter(x, 0, 0, ridge, midZ, rW, rH, roofColor);
        addRafter(x, 0, W, ridge, midZ, rW, rH, roofColor);
      }
      addBox(0, ridge - rH / 2, midZ - rW / 2, L, rH, rW, ridgeColor);
    } else {
      for (double x = pW * 2; x < L - pW; x += spacing) {
        addBox(x, pH, pW, jW, jH, W - 2 * pW, joistColor);
      }
      addBox(0, 0, 0, L, pH, pW, wood);
      addBox(0, 0, W - pW, L, pH, pW, wood);
      addBox(0, 0, pW, pW, pH, W - 2 * pW, wood);
      addBox(L - pW, 0, pW, pW, pH, W - 2 * pW, wood);

      for (double x = pW; x < L - 0.1; x += spacing) {
        addBox(x, pH, 0, sW, H - pH * 2, sW, studColor);
        addBox(x, pH, W - sW, sW, H - pH * 2, sW, studColor);
      }
      for (double z = pW * 2; z < W - 0.1; z += spacing) {
        addBox(0, pH, z, sW, H - pH * 2, sW, studColor);
        addBox(L - sW, pH, z, sW, H - pH * 2, sW, studColor);
      }
      addBox(0, pH, 0, sW, H - pH * 2, sW, studColor);
      addBox(L - sW, pH, 0, sW, H - pH * 2, sW, studColor);
      addBox(0, pH, W - sW, sW, H - pH * 2, sW, studColor);
      addBox(L - sW, pH, W - sW, sW, H - pH * 2, sW, studColor);

      addBox(0, H - pH, 0, L, pH, pW, wood);
      addBox(0, H - pH, W - pW, L, pH, pW, wood);
      addBox(0, H - pH, pW, pW, pH, W - 2 * pW, wood);
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
        addBox(0, ridgeY - rH / 2, midZ - rW / 2, L, rH, rW, ridgeColor);
      }
    }

    faces.sort((a, b) => b.depth.compareTo(a.depth));

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

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
