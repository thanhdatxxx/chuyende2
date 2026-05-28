import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      List<String> tracks = [
        'assets/audio/bai1.mp3',
        'assets/audio/bai2.ogg',
        'assets/audio/bai3.ogg',
      ];

      try {
        final doc = await FirebaseFirestore.instance
            .collection('system_settings')
            .doc('ui_settings')
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['music'] != null) {
            tracks = List<String>.from(data['music']);
          }
        }
      } catch (e) {
        debugPrint('Lỗi tải danh sách nhạc từ Firestore: $e');
      }

      final playlist = ConcatenatingAudioSource(
        children: tracks.map((track) {
          if (track.startsWith('http') || track.startsWith('https')) {
            return AudioSource.uri(Uri.parse(track));
          } else {
            return AudioSource.asset(track);
          }
        }).toList(),
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

  Future<void> updatePlaylist(List<String> newTracks) async {
    try {
      final wasPlaying = _player.playing;
      if (wasPlaying) {
        await _player.stop();
      }

      final playlist = ConcatenatingAudioSource(
        children: newTracks.map((track) {
          if (track.startsWith('http') || track.startsWith('https')) {
            return AudioSource.uri(Uri.parse(track));
          } else {
            return AudioSource.asset(track);
          }
        }).toList(),
      );

      await _player.setAudioSource(playlist);
      _isReady = true;

      if (wasPlaying) {
        await _player.play();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi cập nhật danh sách nhạc: $e');
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
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

