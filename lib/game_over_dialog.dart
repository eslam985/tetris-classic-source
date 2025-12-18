import 'dart:ui';
import 'package:flutter/material.dart';

class GameOverDialog extends StatelessWidget {
  final int score;
  final int lines;
  final int level;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  const GameOverDialog({
    super.key,
    required this.score,
    required this.lines,
    required this.level,
    required this.onRestart,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    // استخدمنا BackdropFilter عشان يدي تأثير احترافي ورا الشاشة
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: Container(
          width: 350, // عرض مناسب للـ Dialog
          // قللنا الـ padding شوية عشان ندي مساحة أكبر للمحتوى
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          // الـ SingleChildScrollView هو الحماية ضد الـ Overflow
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gavel_rounded,
                    size: 60, color: Colors.redAccent),
                const SizedBox(height: 10),
                // FittedBox عشان كلمة Game Over متخرجش بره العرض
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'GAME OVER',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const Divider(color: Colors.white10, height: 30),

                // سكشن الإحصائيات
                _buildStatDetail('FINAL SCORE', '$score', Colors.orangeAccent),
                _buildStatDetail('LINES CLEARED', '$lines', Colors.blueAccent),
                _buildStatDetail('LEVEL REACHED', '$level', Colors.greenAccent),

                const SizedBox(height: 30),

                // الزراير
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: onQuit,
                        child: const Text('QUIT',
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onRestart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('RESTART',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لتنظيم السطور جوه الـ Dialog
  Widget _buildStatDetail(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
