import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playTypingSound() async {
    await _player.play(AssetSource('sounds/typing.wav'));
  }

  Future<void> playResponseSound() async {
    await _player.play(AssetSource('sounds/response.wav'));
  }

  void dispose() {
    _player.dispose();
  }
}
