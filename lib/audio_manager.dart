import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static bool isMuted = false;
  static double volume = 0.7;

  // 1. تعريف الـ Pools لكل المؤثرات الصوتية لضمان استجابة لحظية (Zero Latency)
  static AudioPool? _movePool;
  static AudioPool? _rotatePool;
  static AudioPool? _dropPool;
  static AudioPool? _lineClearPool;
  static AudioPool? _gameOverPool;

  static Future<void> loadSounds() async {
    // 2. تحميل الموسيقى الخلفية في الكاش (لأنها ملف طويل)
    await FlameAudio.audioCache.loadAll(['theme.mp3']);

    // 3. إنشاء الـ Pools للمؤثرات السريعة
    // maxPlayers: عدد القنوات المفتوحة في نفس الوقت عشان الأصوات ما تقطعش بعضها
    _movePool = await FlameAudio.createPool(
      'move.mp3',
      maxPlayers: 4,
    );

    _rotatePool = await FlameAudio.createPool(
      'rotate.mp3',
      maxPlayers: 2,
    );

    _dropPool = await FlameAudio.createPool(
      'drop.mp3',
      maxPlayers: 2,
    );

    _lineClearPool = await FlameAudio.createPool(
      'line_clear.mp3',
      maxPlayers: 2,
    );

    _gameOverPool = await FlameAudio.createPool(
      'game_over.mp3',
      maxPlayers: 1,
    );
  }

  // استخدام .start() مع الـ Pool هو السر في ليفل 8
  static void playMove() {
    if (isMuted || _movePool == null) return;
    _movePool!.start(volume: volume * 0.3);
  }

  static void playRotate() {
    if (isMuted || _rotatePool == null) return;
    _rotatePool!.start(volume: volume * 0.4);
  }

  static void playDrop() {
    if (isMuted || _dropPool == null) return;
    _dropPool!.start(volume: volume * 0.5);
  }

  static void playLineClear() {
    if (isMuted || _lineClearPool == null) return;
    _lineClearPool!.start(volume: volume);
  }

  static void playGameOver() {
    if (isMuted || _gameOverPool == null) return;
    _gameOverPool!.start(volume: volume);
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
