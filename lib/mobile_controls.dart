import 'package:flutter/material.dart';

class MobileControls extends StatelessWidget {
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onRotate;
  final VoidCallback onDrop;
  final VoidCallback onHardDrop;
  
  const MobileControls({
    super.key,
    required this.onLeft,
    required this.onRight,
    required this.onRotate,
    required this.onDrop,
    required this.onHardDrop,
  });
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // زر الدوران
              _ControlButton(
                icon: Icons.rotate_right,
                onPressed: onRotate,
                color: Colors.blue,
              ),
              const SizedBox(width: 20),
              // زر الهارد دروب
              _ControlButton(
                icon: Icons.arrow_drop_down,
                onPressed: onHardDrop,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // زر اليسار
              _ControlButton(
                icon: Icons.arrow_left,
                onPressed: onLeft,
                color: Colors.green,
              ),
              const SizedBox(width: 60),
              // زر اليمين
              _ControlButton(
                icon: Icons.arrow_right,
                onPressed: onRight,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // زر السقوط
          _ControlButton(
            icon: Icons.arrow_downward,
            onPressed: onDrop,
            color: Colors.orange,
            isLarge: true,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final bool isLarge;
  
  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    this.isLarge = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onPressed(),
      child: Container(
        width: isLarge ? 120 : 70,
        height: isLarge ? 70 : 70,
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: isLarge ? 40 : 30,
          color: Colors.white,
        ),
      ),
    );
  }
}