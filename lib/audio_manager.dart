import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static bool isMuted = false;
  static double volume = 0.7;

  static AudioPool? _movePool;
  static AudioPool? _rotatePool;
  static AudioPool? _dropPool;
  static AudioPool? _lineClearPool;
  static AudioPool? _gameOverPool;

  static Future<void> loadSounds() async {
    // عزل كامل للتحميل
    return;
  }

  static void playMove() {
    // عزل كامل للتشغيل
    return;
  }

  static void playRotate() {
    return;
  }

  static void playDrop() {
    return;
  }

  static void playLineClear() {
    return;
  }

  static void playGameOver() {
    return;
  }

  static void playBackgroundMusic() {
    return;
  }

  static void stopBackgroundMusic() => FlameAudio.bgm.stop();

  static void toggleMute() {
    isMuted = !isMuted;
  }
}
