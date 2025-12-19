import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static bool isMuted = false;
  static double volume = 0.7;

  // هنستخدم AudioPlayer ثابت لكل صوت عشان نمنع الـ Overhead بتاع إنشاء لاعب جديد
  static late AudioPlayer _movePlayer;
  static late AudioPlayer _rotatePlayer;
  static late AudioPlayer _dropPlayer;

  static Future<void> loadSounds() async {
    // تحميل مسبق في الكاش
    await FlameAudio.audioCache.loadAll([
      'move.mp3',
      'rotate.mp3',
      'drop.mp3',
      'line_clear.mp3',
      'game_over.mp3',
      'theme.mp3',
    ]);

    // تثبيت اللاعبين للأصوات الأكثر تكراراً
    _movePlayer = await FlameAudio.play('move.mp3', volume: 0);
    _rotatePlayer = await FlameAudio.play('rotate.mp3', volume: 0);
    _dropPlayer = await FlameAudio.play('drop.mp3', volume: 0);
  }

  static void playMove() async {
    if (isMuted) return;
    // السر هنا: بنعمل Seek للبداية وبنشغل نفس اللاعب بدل ما نفتح واحد جديد
    await _movePlayer.stop();
    _movePlayer.play(AssetSource('sounds/move.mp3'), volume: volume * 0.5);
  }

  static void playRotate() async {
    if (isMuted) return;
    await _rotatePlayer.stop();
    _rotatePlayer.play(AssetSource('sounds/rotate.mp3'), volume: volume * 0.6);
  }

  static void playDrop() async {
    if (isMuted) return;
    await _dropPlayer.stop();
    _dropPlayer.play(AssetSource('sounds/drop.mp3'), volume: volume * 0.8);
  }

  // الأصوات اللي مش بتتكرر كتير نسيبها عادية
  static void _playQuickSound(String fileName, {double? customVolume}) {
    if (isMuted) return;
    FlameAudio.play(fileName, volume: customVolume ?? volume);
  }

  static void playLineClear() => _playQuickSound('line_clear.mp3');
  static void playGameOver() => _playQuickSound('game_over.mp3');

  static void playBackgroundMusic() {
    if (!isMuted) {
      if (!FlameAudio.bgm.isPlaying) {
        FlameAudio.bgm.play('theme.mp3', volume: volume * 0.4);
      }
    }
  }

  static void stopBackgroundMusic() => FlameAudio.bgm.stop();

  static void toggleMute() {
    isMuted = !isMuted;
    if (isMuted) {
      stopBackgroundMusic();
      _movePlayer.stop();
      _rotatePlayer.stop();
    } else {
      playBackgroundMusic();
    }
  }
}
