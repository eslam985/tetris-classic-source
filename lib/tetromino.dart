import 'package:flutter/material.dart';
import 'dart:math';

class Block {
  final int dx;
  final int dy;

  const Block(this.dx, this.dy);
}

class Tetromino {
  final int type;
  final int x;
  final int y;
  final int rotation;
  final List<Block> blocks;

  // 1. تعريف أدوات الرسم "مرة واحدة" كـ static لتوفير الرامات ومنع "النتشة"
  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  static final Paint _borderPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static final Paint _highlightPaint = Paint()..style = PaintingStyle.fill;

  static const Map<int, List<List<Block>>> shapes = {
    1: [
      // I
      [Block(0, 1), Block(1, 1), Block(2, 1), Block(3, 1)],
      [Block(2, 0), Block(2, 1), Block(2, 2), Block(2, 3)],
      [Block(0, 2), Block(1, 2), Block(2, 2), Block(3, 2)],
      [Block(1, 0), Block(1, 1), Block(1, 2), Block(1, 3)],
    ],
    2: [
      // J
      [Block(0, 0), Block(0, 1), Block(1, 1), Block(2, 1)],
      [Block(1, 0), Block(2, 0), Block(1, 1), Block(1, 2)],
      [Block(0, 1), Block(1, 1), Block(2, 1), Block(2, 2)],
      [Block(1, 0), Block(1, 1), Block(0, 2), Block(1, 2)],
    ],
    3: [
      // L
      [Block(2, 0), Block(0, 1), Block(1, 1), Block(2, 1)],
      [Block(1, 0), Block(1, 1), Block(1, 2), Block(2, 2)],
      [Block(0, 1), Block(1, 1), Block(2, 1), Block(0, 2)],
      [Block(0, 0), Block(1, 0), Block(1, 1), Block(1, 2)],
    ],
    4: [
      // O
      [Block(1, 0), Block(2, 0), Block(1, 1), Block(2, 1)],
      [Block(1, 0), Block(2, 0), Block(1, 1), Block(2, 1)],
      [Block(1, 0), Block(2, 0), Block(1, 1), Block(2, 1)],
      [Block(1, 0), Block(2, 0), Block(1, 1), Block(2, 1)],
    ],
    5: [
      // S
      [Block(1, 0), Block(2, 0), Block(0, 1), Block(1, 1)],
      [Block(1, 0), Block(1, 1), Block(2, 1), Block(2, 2)],
      [Block(1, 1), Block(2, 1), Block(0, 2), Block(1, 2)],
      [Block(0, 0), Block(0, 1), Block(1, 1), Block(1, 2)],
    ],
    6: [
      // T
      [Block(1, 0), Block(0, 1), Block(1, 1), Block(2, 1)],
      [Block(1, 0), Block(1, 1), Block(2, 1), Block(1, 2)],
      [Block(0, 1), Block(1, 1), Block(2, 1), Block(1, 2)],
      [Block(1, 0), Block(0, 1), Block(1, 1), Block(1, 2)],
    ],
    7: [
      // Z
      [Block(0, 0), Block(1, 0), Block(1, 1), Block(2, 1)],
      [Block(2, 0), Block(1, 1), Block(2, 1), Block(1, 2)],
      [Block(0, 1), Block(1, 1), Block(1, 2), Block(2, 2)],
      [Block(1, 0), Block(0, 1), Block(1, 1), Block(0, 2)],
    ],
  };

  static const Map<int, Color> colors = {
    1: Color(0xFF00BCD4), // I - Cyan
    2: Color(0xFF2196F3), // J - Blue
    3: Color(0xFFFF9800), // L - Orange
    4: Color(0xFFFFEB3B), // O - Yellow
    5: Color(0xFF4CAF50), // S - Green
    6: Color(0xFF9C27B0), // T - Purple
    7: Color(0xFFF44336), // Z - Red
  };

  Tetromino({
    required this.type,
    required this.x,
    required this.y,
    required this.rotation,
    required this.blocks,
  });

  factory Tetromino.getRandom() {
    final random = Random();
    final type = random.nextInt(7) + 1;
    const initialX = 3; // وضعية البداية في منتصف الشبكة 10x20

    return Tetromino(
      type: type,
      x: initialX,
      y: 0,
      rotation: 0,
      blocks: shapes[type]![0],
    );
  }

  static Color getColor(int type) {
    return colors[type] ?? Colors.grey;
  }

  Tetromino copyWith({int? x, int? y, int? rotation}) {
    final newRotation = rotation ?? this.rotation;
    return Tetromino(
      type: type,
      x: x ?? this.x,
      y: y ?? this.y,
      rotation: newRotation,
      blocks: shapes[type]![newRotation % 4],
    );
  }

  List<Point<int>> getWallKicks() {
    return [
      const Point(0, 0),
      const Point(-1, 0),
      const Point(1, 0),
      const Point(0, -1),
      const Point(-1, -1),
      const Point(1, -1),
    ];
  }

  // 2. دالة الرسم المحسنة للأداء العالي (Level 8 Ready)
  void render(Canvas canvas, double startX, double startY, double cellSize) {
    _fillPaint.color = colors[type]!;
    _highlightPaint.color = Colors.white.withValues(alpha: 0.3);

    for (final block in blocks) {
      final cellX = startX + (x + block.dx) * cellSize;
      final cellY = startY + (y + block.dy) * cellSize;
      final rect =
          Rect.fromLTWH(cellX + 0.5, cellY + 0.5, cellSize - 1, cellSize - 1);

      // رسم الجسم الأساسي
      canvas.drawRect(rect, _fillPaint);

      // رسم الحدود (بدون إنشاء كائن Paint جديد)
      canvas.drawRect(rect, _borderPaint);

      // رسم اللمعة الجمالية
      canvas.drawRect(
        Rect.fromLTWH(cellX + 2, cellY + 2, cellSize - 6, 2),
        _highlightPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(cellX + 2, cellY + 2, 2, cellSize - 6),
        _highlightPaint,
      );
    }
  }
}
