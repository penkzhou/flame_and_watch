import 'package:flame/flame.dart';
import 'package:flame_and_watch/flame_and_watch.dart';
import 'package:flame_and_watch/settings_manager.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await FlameAudio.audioCache.loadAll([
      'sfxs/drown.wav',
      'sfxs/rescue.wav',
      'sfxs/gameover.wav',
    ]);
    await Flame.device.fullScreen();
    await Flame.device.setLandscape();
  }
  await SettingsManager.load();

  runApp(FlameAndWatchScreen());
}
