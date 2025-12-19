import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static bool isMuted = false;
  static double volume = 0.7;

  // تعريف الـ Pools للأصوات المتكررة
  static AudioPool? _movePool;
  static AudioPool? _rotatePool;

  static Future<void> loadSounds() async {
    // 1. تحميل الموسيقى والأصوات التقيلة
    await FlameAudio.audioCache.loadAll([
      'line_clear.mp3',
      'game_over.mp3',
      'theme.mp3',
      'drop.mp3',
    ]);

    // 2. إنشاء Pool للأصوات اللي بتشتغل كتير ورا بعض
    _movePool = await FlameAudio.createPool(
      'move.mp3',
      maxPlayers: 3, // أقصى عدد أصوات يشتغلوا في نفس اللحظة
    );

    _rotatePool = await FlameAudio.createPool(
      'rotate.mp3',
      maxPlayers: 2,
    );
  }

  static void playMove() {
    if (isMuted || _movePool == null) return;
    // الـ Pool أسرع بـ 10 مرات من play العادية
    _movePool!.start(volume: volume * 0.3);
  }

  static void playRotate() {
    if (isMuted || _rotatePool == null) return;
    _rotatePool!.start(volume: volume * 0.4);
  }

  static void playDrop() {
    if (isMuted) return;
    // الـ drop مش محتاج pool لأنه بيحصل مرة واحدة كل فترة
    FlameAudio.play('drop.mp3', volume: volume * 0.5);
  }

  static void playLineClear() {
    if (isMuted) return;
    FlameAudio.play('line_clear.mp3', volume: volume);
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
