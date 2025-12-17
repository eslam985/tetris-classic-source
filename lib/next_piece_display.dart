import 'dart:math';
import 'package:flutter/material.dart';
import 'tetromino.dart';

class NextPieceDisplay extends StatelessWidget {
  final Tetromino? nextPiece;
  const NextPieceDisplay({super.key, this.nextPiece});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: nextPiece == null
          ? Center(
              child: Icon(
                Icons.question_mark,
                color: Colors.white24,
                size: 32,
              ),
            )
          : CustomPaint(
              painter: _NextPiecePainter(nextPiece!),
            ),
    );
  }
}

class _NextPiecePainter extends CustomPainter {
  final Tetromino nextPiece;
  
  _NextPiecePainter(this.nextPiece);

  @override
  void paint(Canvas canvas, Size size) {
    final blocks = nextPiece.blocks;
    
    if (blocks.isEmpty) return;
    
    int minX = 4, maxX = 0, minY = 4, maxY = 0;
    for (final block in blocks) {
      minX = block.dx < minX ? block.dx : minX;
      maxX = block.dx > maxX ? block.dx : maxX;
      minY = block.dy < minY ? block.dy : minY;
      maxY = block.dy > maxY ? block.dy : maxY;
    }
    
    final pieceWidth = maxX - minX + 1;
    final pieceHeight = maxY - minY + 1;
    
    final maxDimension = max(pieceWidth, pieceHeight);
    final cellSize = min(size.width, size.height) / (maxDimension + 1);
    
    final offsetX = (size.width - pieceWidth * cellSize) / 2;
    final offsetY = (size.height - pieceHeight * cellSize) / 2;
    
    final color = Tetromino.getColor(nextPiece.type);
    
    for (final block in blocks) {
      final x = offsetX + (block.dx - minX) * cellSize;
      final y = offsetY + (block.dy - minY) * cellSize;
      
      final paint = Paint()..color = color;
      canvas.drawRect(
        Rect.fromLTWH(x + 1, y + 1, cellSize - 2, cellSize - 2),
        paint,
      );
      
      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(
        Rect.fromLTWH(x + 1, y + 1, cellSize - 2, cellSize - 2),
        borderPaint,
      );
      
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(x + 2, y + 2, cellSize - 6, 2),
        highlightPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(x + 2, y + 2, 2, cellSize - 6),
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 