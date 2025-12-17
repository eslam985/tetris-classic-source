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
    if (!isMuted) FlameAudio.play('move.wav', volume: volume);
  }

  static void playRotate() {
    if (!isMuted) FlameAudio.play('rotate.wav', volume: volume);
  }

  static void playDrop() {
    if (!isMuted) FlameAudio.play('drop.wav', volume: volume * 0.8);
  }

  static void playLineClear() {
    if (!isMuted) FlameAudio.play('line_clear.wav', volume: volume);
  }

  static void playGameOver() {
    if (!isMuted) FlameAudio.play('game_over.wav', volume: volume);
  }

  static void playBackgroundMusic() {
    if (!isMuted) {
      FlameAudio.bgm.play('theme.mp3', volume: volume * 0.5);
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
