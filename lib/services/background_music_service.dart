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
    // Lắng nghe trạng thái thực tế từ trình phát nhạc để cập nhật UI chính xác
    _player.playingStream.listen((playing) {
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
      final playlist = ConcatenatingAudioSource(
        children: [
          AudioSource.asset('assets/audio/bai1.mp3'),
          AudioSource.asset('assets/audio/bai2.ogg'),
          AudioSource.asset('assets/audio/bai3.ogg'),
        ],
      );

      await _player.setAudioSource(playlist);
      await _player.setLoopMode(LoopMode.all);
      await _player.setVolume(0.45);
      
      _isReady = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi khởi tạo nhạc nền: $e');
      _isReady = false;
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
    } else {
      try {
        await _player.play();
      } catch (e) {
        debugPrint('Không thể phát nhạc: $e');
      }
    }
    // _isPlaying sẽ được cập nhật tự động qua listener ở constructor
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
