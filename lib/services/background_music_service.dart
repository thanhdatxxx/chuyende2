import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class BackgroundMusicService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;
  bool _isReady = false;
  bool _isInitializing = false;

  bool get isPlaying => _isPlaying;
  bool get isReady => _isReady;

  BackgroundMusicService() {
    _player.playerStateStream.listen((state) {
      final playing = state.playing;
      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }
    });
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      // Ưu tiên 2 bài nhạc nền; nếu codec không hỗ trợ trên một nền tảng,
      // sẽ fallback playlist tương thích hơn để nút nhạc luôn hoạt động.
      bool ready = false;

      final playlistCandidates = <List<AudioSource>>[
        [
          AudioSource.asset('assets/audio/bai1.mp3'),
          AudioSource.asset('assets/audio/bai2.ogg'),
        ],
        [
          AudioSource.asset('assets/audio/bai1.mp3'),
          AudioSource.asset('assets/audio/bai3.ogg'),
        ],
        [AudioSource.asset('assets/audio/bai1.mp3')],
      ];

      for (final sources in playlistCandidates) {
        try {
          if (sources.length == 1) {
            await _player.setAudioSource(sources.first);
          } else {
            await _player.setAudioSource(
              ConcatenatingAudioSource(children: sources),
            );
          }
          ready = true;
          break;
        } catch (_) {
          // thử candidate tiếp theo
        }
      }

      if (!ready) {
        throw Exception('No playable audio source');
      }

      await _player.setLoopMode(LoopMode.all);
      await _player.setVolume(0.45);
      _isReady = true;
      _isPlaying = false;
      notifyListeners();
    } catch (_) {
      _isReady = false;
      _isPlaying = false;
      notifyListeners();
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> toggle() async {
    if (!_isReady) {
      await _initialize();
      if (!_isReady) return;
    }

    if (_player.playing) {
      await _player.pause();
      _isPlaying = false;
    } else {
      await _player.play();
      _isPlaying = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

