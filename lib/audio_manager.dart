import 'dart:io' show Platform; // عشان نعرف نوع الجهاز
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // عشان لو حبيت ترفعها ويب

class AudioManager {
  static bool isMuted = false;
  static double volume = 0.5;

  static Future<void> loadSounds() async {
    // ملفات أساسية لكل الأجهزة
    await FlameAudio.audioCache
        .loadAll(['line_clear.mp3', 'game_over.mp3', 'theme.mp3']);

    // لو مش موبايل (يعني ويندوز أو ماك)، حمل ملفات الحركة
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      await FlameAudio.audioCache
          .loadAll(['move.mp3', 'rotate.mp3', 'drop.mp3']);
    }
  }

  static void playMove() {
    if (isMuted) return;

    // لو موبايل: استخدم أصوات النظام السريعة (تجنباً للاج والكراش)
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.selectionClick();
    } else {
      // لو ديسكتوب: شغل الملف عادي (عشان مفيش اهتزاز)
      FlameAudio.play('move.mp3', volume: volume * 0.3);
    }
  }

  static void playRotate() {
    if (isMuted) return;

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    } else {
      FlameAudio.play('rotate.mp3', volume: volume * 0.4);
    }
  }

  static void playDrop() {
    if (isMuted) return;

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.mediumImpact();
    } else {
      FlameAudio.play('drop.mp3', volume: volume * 0.5);
    }
  }

  static void playLineClear() {
    if (isMuted) return;

    // الحل هنا: استخدمنا دالة play العادية بس اتأكدنا إن الـ bgm لسه شغال
    FlameAudio.play('line_clear.mp3', volume: volume);

    // حركة صايعة للموبايل: لو الموسيقى وقفت لسبب ما، رجعها
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      HapticFeedback.heavyImpact();
      // تأكيد تشغيل الموسيقى لو حصل "Focus Loss"
      if (!FlameAudio.bgm.isPlaying && !isMuted) {
        FlameAudio.bgm.resume();
      }
    }
  }

  static void playGameOver() {
    if (isMuted) return;
    FlameAudio.play('game_over.mp3', volume: volume);
  }

  static void playBackgroundMusic() {
    if (!isMuted && !FlameAudio.bgm.isPlaying) {
      FlameAudio.bgm.play('theme.mp3', volume: volume * 0.2);
    }
  }

  static void stopBackgroundMusic() => FlameAudio.bgm.stop();

  static void toggleMute() {
    isMuted = !isMuted;
    if (isMuted) {
      stopBackgroundMusic();
    } else {
      playBackgroundMusic();
    }
  }
}
