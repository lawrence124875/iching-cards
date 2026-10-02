import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'audio_playback.dart';

class JustAudioPlayback implements AudioPlayback {
  final _player = AudioPlayer();

  @override
  Future<Duration?> load(String filePath) => _player.setFilePath(filePath);

  @override
  Future<void> play() async {
    // just_audio 的 play() 要到停止播放才會完成，不能 await
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Duration get position => _player.position;

  @override
  Future<void> dispose() => _player.dispose();
}
