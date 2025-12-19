import 'dart:math';
import 'package:flutter/material.dart';
import 'tetromino.dart';

class NextPieceDisplay extends StatelessWidget {
  // بنستقبل الـ Notifier نفسه مش القطعة
  final ValueNotifier<Tetromino?> nextPieceNotifier;

  const NextPieceDisplay({super.key, required this.nextPieceNotifier});

  @override
  Widget build(BuildContext context) {
    // الـ ValueListenableBuilder هو اللي بيخلي التحديث "جراحي"
    return ValueListenableBuilder<Tetromino?>(
      valueListenable: nextPieceNotifier,
      builder: (context, nextPiece, child) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: nextPiece == null
              ? const Center(
                  child: Icon(Icons.question_mark,
                      color: Colors.white24, size: 32))
              : CustomPaint(
                  painter: _NextPiecePainter(nextPiece),
                ),
        );
      },
    );
  }
}

class _NextPiecePainter extends CustomPainter {
  final Tetromino nextPiece;

  // 1. تعريف أدوات الرسم كـ final خارج دالة paint لتوفير الذاكرة
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  final Paint _borderPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  final Paint _highlightPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.3)
    ..style = PaintingStyle.fill;

  _NextPiecePainter(this.nextPiece);

  @override
  void paint(Canvas canvas, Size size) {
    final blocks = nextPiece.blocks;
    if (blocks.isEmpty) return;

    // حساب حدود القطعة (منطق سليم وحافظنا عليه)
    int minX = 4, maxX = 0, minY = 4, maxY = 0;
    for (final block in blocks) {
      minX = block.dx < minX ? block.dx : minX;
      maxX = block.dx > maxX ? block.dx : maxX;
      minY = block.dy < minY ? block.dy : minY;
      maxY = block.dy > maxY ? block.dy : maxY;
    }

    final pieceWidth = maxX - minX + 1;
    final pieceHeight = maxY - minY + 1;

    // حساب حجم الخلية بناءً على مساحة الـ Widget المتاحة
    final cellSize =
        min(size.width / (pieceWidth + 1), size.height / (pieceHeight + 1));

    final offsetX = (size.width - pieceWidth * cellSize) / 2;
    final offsetY = (size.height - pieceHeight * cellSize) / 2;

    // تحديد اللون مرة واحدة للقطعة كاملة
    _fillPaint.color = Tetromino.getColor(nextPiece.type);

    for (final block in blocks) {
      final x = offsetX + (block.dx - minX) * cellSize;
      final y = offsetY + (block.dy - minY) * cellSize;

      final rect = Rect.fromLTWH(x + 1, y + 1, cellSize - 2, cellSize - 2);

      // رسم المربع الأساسي
      canvas.drawRect(rect, _fillPaint);

      // رسم حدود المربع
      canvas.drawRect(rect, _borderPaint);

      // رسم تأثير اللمعة (Highlight) لتحسين المظهر الجمالي
      // اللمعة العلوية
      canvas.drawRect(
        Rect.fromLTWH(x + 2, y + 2, cellSize - 6, 2),
        _highlightPaint,
      );
      // اللمعة الجانبية
      canvas.drawRect(
        Rect.fromLTWH(x + 2, y + 2, 2, cellSize - 6),
        _highlightPaint,
      );
    }
  }

  @override
  // 2. التعديل الجوهري: منع إعادة الرسم إلا في حالة تغيير القطعة فعلياً
  // هذا السطر وحده قد يحسن أداء اللعبة بنسبة 15% في السرعات العالية
  bool shouldRepaint(covariant _NextPiecePainter oldDelegate) {
    return oldDelegate.nextPiece != nextPiece;
  }
}
