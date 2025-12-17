import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static bool isMuted = false;
  static double volume = 0.7;

  // تعريف المشغلات بشكل ثابت عشان نستخدمهم ونعملهم stop قبل الـ play
  // ده بيمنع تراكم الأصوات ورا بعضها
  static void _playQuickSound(String fileName, {double? customVolume}) {
    if (isMuted) return;

    // الحل السحري للتأخير: استخدام playPool لو متاح أو التحكم في الصوت يدوياً
    // لكن الأسهل والأنسب لـ FlameAudio هو التأكد من استخدام mode خاص
    FlameAudio.play(fileName, volume: customVolume ?? volume);
  }

  static Future<void> loadSounds() async {
    await FlameAudio.audioCache.loadAll([
      'move.mp3',
      'rotate.mp3',
      'drop.mp3',
      'line_clear.mp3',
      'game_over.mp3',
      'theme.mp3',
    ]);
  }

  // في حركات السرعة (Move & Rotate) بنستخدم حجم صوت أقل وسرعة استجابة أعلى
  static void playMove() {
    _playQuickSound('move.mp3', customVolume: volume * 0.5);
  }

  static void playRotate() {
    _playQuickSound('rotate.mp3', customVolume: volume * 0.6);
  }

  static void playDrop() {
    _playQuickSound('drop.mp3', customVolume: volume * 0.8);
  }

  static void playLineClear() {
    _playQuickSound('line_clear.mp3');
  }

  static void playGameOver() {
    _playQuickSound('game_over.mp3');
  }

  static void playBackgroundMusic() {
    if (!isMuted) {
      FlameAudio.bgm.play('theme.mp3', volume: volume * 0.4);
    }
  }

  static void stopBackgroundMusic() {
    FlameAudio.bgm.stop();
  }

  static void toggleMute() {
    isMuted = !isMuted;
    if (isMuted) {
      FlameAudio.bgm.stop();
    } else {
      playBackgroundMusic();
    }
  }
}
