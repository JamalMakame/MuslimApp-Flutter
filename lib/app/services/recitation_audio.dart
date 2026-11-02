import 'package:audio_service/audio_service.dart';

/// Lock-screen / notification controls and background playback for the
/// reader and Hifz. The screen that is playing [attach]es its callbacks and
/// [report]s what it plays; a null [instance] (tests) makes every call a
/// no-op.
class RecitationAudio extends BaseAudioHandler {
  static RecitationAudio? instance;

  static Future<void> init() async {
    try {
      instance = await AudioService.init(
        builder: RecitationAudio.new,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.jamalmakame.deen.recitation',
          androidNotificationChannelName: 'Recitation',
          androidNotificationIcon: 'drawable/ic_notification',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
    } catch (_) {
      instance = null;
    }
  }

  Object? _owner;
  Future<void> Function()? _play, _pause, _next, _prev, _stop;

  static void attach(
    Object owner, {
    required Future<void> Function() play,
    required Future<void> Function() pause,
    required Future<void> Function() stop,
    Future<void> Function()? next,
    Future<void> Function()? prev,
  }) {
    final h = instance;
    if (h == null) return;
    h
      .._owner = owner
      .._play = play
      .._pause = pause
      .._stop = stop
      .._next = next
      .._prev = prev;
  }

  /// Clears the controls when [owner] (a closing screen) still holds them.
  static void detach(Object owner) {
    final h = instance;
    if (h == null || !identical(h._owner, owner)) return;
    h
      .._owner = null
      .._play = null
      .._pause = null
      .._stop = null
      .._next = null
      .._prev = null;
    h.playbackState.add(
      PlaybackState(processingState: AudioProcessingState.idle),
    );
  }

  /// What [owner] is playing and whether it is.
  static void report(
    Object owner, {
    required String title,
    required String artist,
    required bool playing,
    bool loading = false,
  }) {
    final h = instance;
    if (h == null || !identical(h._owner, owner)) return;
    final id = '$title|$artist';
    if (h.mediaItem.value?.id != id) {
      h.mediaItem.add(
        MediaItem(id: id, title: title, artist: artist, album: 'Deen'),
      );
    }
    final controls = [
      if (h._prev != null) MediaControl.skipToPrevious,
      playing ? MediaControl.pause : MediaControl.play,
      if (h._next != null) MediaControl.skipToNext,
      MediaControl.stop,
    ];
    h.playbackState.add(
      PlaybackState(
        controls: controls,
        // Compact (collapsed) view: everything except stop.
        androidCompactActionIndices: [
          for (var i = 0; i < controls.length - 1; i++) i,
        ],
        processingState: loading
            ? AudioProcessingState.loading
            : AudioProcessingState.ready,
        playing: playing,
      ),
    );
  }

  @override
  Future<void> play() async => _play?.call();

  @override
  Future<void> pause() async => _pause?.call();

  @override
  Future<void> skipToNext() async => _next?.call();

  @override
  Future<void> skipToPrevious() async => _prev?.call();

  @override
  Future<void> stop() async {
    await _stop?.call();
    playbackState.add(
      PlaybackState(processingState: AudioProcessingState.idle),
    );
  }
}
