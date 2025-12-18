import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static bool isMuted = false;
  static double volume = 0.7;

  // تعريف الـ Pools للأصوات السريعة عشان نمنع التأخير
  static AudioPool? _movePool;
  static AudioPool? _rotatePool;

  static Future<void> loadSounds() async {
    // تحميل الـ Pools مسبقاً (ده اللي بيخلي الصوت طلقة)
    _movePool = await FlameAudio.createPool('move.mp3', maxPlayers: 1);
    _rotatePool = await FlameAudio.createPool('rotate.mp3', maxPlayers: 1);

    await FlameAudio.audioCache.loadAll([
      'drop.mp3',
      'line_clear.mp3',
      'game_over.mp3',
      'theme.mp3',
    ]);
  }

  static void playMove() {
    if (isMuted || _movePool == null) return;
    _movePool!.start(volume: volume * 0.5);
  }

  static void playRotate() {
    if (isMuted || _rotatePool == null) return;
    _rotatePool!.start(volume: volume * 0.6);
  }

  // باقي الأصوات زي ما هي لأنها مش بتتكرر ورا بعضها بسرعة جنونية
  static void _playQuickSound(String fileName, {double? customVolume}) {
    if (isMuted) return;
    FlameAudio.play(fileName, volume: customVolume ?? volume);
  }

  static void playDrop() =>
      _playQuickSound('drop.mp3', customVolume: volume * 0.8);
  static void playLineClear() => _playQuickSound('line_clear.mp3');
  static void playGameOver() => _playQuickSound('game_over.mp3');

  static void playBackgroundMusic() {
    if (!isMuted) FlameAudio.bgm.play('theme.mp3', volume: volume * 0.4);
  }

  static void stopBackgroundMusic() => FlameAudio.bgm.stop();

  static void toggleMute() {
    isMuted = !isMuted;
    isMuted ? FlameAudio.bgm.stop() : playBackgroundMusic();
  }
}
