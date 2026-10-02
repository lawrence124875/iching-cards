import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'audio_playback.dart';

/// 以 just_audio 播放；搭配 just_audio_background（main.dart 初始化），
/// 離開 App 或關閉螢幕仍會繼續播放，並在通知列與鎖定畫面顯示播放狀態與暫停／播放鍵。
class JustAudioPlayback implements AudioPlayback {
  /// 延後建立：必須在 JustAudioBackground.init() 之後才建立播放器。
  late final AudioPlayer _player = AudioPlayer();

  /// main.dart 初始化背景播放的結果；失敗時仍可在前景播放，只是沒有通知控制。
  static bool backgroundReady = false;

  static Future<void> initBackground() async {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.lclab.qiangua.breath',
        androidNotificationChannelName: '呼吸音景',
        androidNotificationIcon: 'drawable/ic_stat_qian', // 單色謙卦卦象（branding/android/res）
      ).timeout(const Duration(seconds: 5));
      backgroundReady = true;
    } catch (_) {
      backgroundReady = false;
    }
  }

  @override
  Future<Duration?> load(
    String filePath, {
    required String id,
    required String title,
    String subtitle = '',
    String? artFilePath,
  }) {
    return _player.setAudioSource(AudioSource.file(
      filePath,
      tag: MediaItem(
        id: id,
        title: title,
        artist: subtitle,
        album: '謙卦',
        artUri: artFilePath == null ? null : Uri.file(artFilePath),
      ),
    ));
  }

  @override
  Future<void> play() async {
    // just_audio 的 play() 要到停止播放才會完成，不能 await
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Duration get position => _player.position;

  @override
  Stream<bool> get playingChanges => _player.playingStream;

  @override
  Stream<void> get completed =>
      _player.processingStateStream.where((s) => s == ProcessingState.completed).map((_) {});
}
