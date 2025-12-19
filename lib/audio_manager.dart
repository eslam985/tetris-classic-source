import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  static bool isMuted = false;
  static double volume = 0.7;

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

  static void playMove() {
    if (isMuted) return;
    FlameAudio.play('move.mp3', volume: volume * 0.3);
  }

  static void playRotate() {
    if (isMuted) return;
    FlameAudio.play('rotate.mp3', volume: volume * 0.4);
  }

  static void playDrop() {
    if (isMuted) return;
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
    isMuted ? stopBackgroundMusic() : playBackgroundMusic();
  }
}
