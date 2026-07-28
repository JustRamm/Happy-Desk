import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  /// Play shredding paper / swoosh sound effect + system haptics
  static Future<void> playShredSound() async {
    try {
      await HapticFeedback.heavyImpact();
      await SystemSound.play(SystemSoundType.click);
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2578/2578-preview.mp3'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.heavyImpact();
    }
  }

  /// Play opening NGL Jar chime / pop sound effect
  static Future<void> playJarOpenSound() async {
    try {
      await HapticFeedback.mediumImpact();
      await SystemSound.play(SystemSoundType.click);
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2568/2568-preview.mp3'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.mediumImpact();
    }
  }

  /// Play Clock-In chime / bell tone
  static Future<void> playClockInSound() async {
    try {
      await HapticFeedback.selectionClick();
      await SystemSound.play(SystemSoundType.click);
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.selectionClick();
    }
  }

  /// Play Clock-Out tone
  static Future<void> playClockOutSound() async {
    try {
      await HapticFeedback.lightImpact();
      await SystemSound.play(SystemSoundType.click);
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2571/2571-preview.mp3'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.lightImpact();
    }
  }

  /// Play Inhale breath tone
  static Future<void> playInhaleSound() async {
    try {
      await HapticFeedback.selectionClick();
      await SystemSound.play(SystemSoundType.click);
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2569/2569-preview.mp3'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.selectionClick();
    }
  }

  /// Play Exhale breath tone
  static Future<void> playExhaleSound() async {
    try {
      await HapticFeedback.lightImpact();
      await SystemSound.play(SystemSoundType.click);
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2570/2570-preview.mp3'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.lightImpact();
    }
  }
}
