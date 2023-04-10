import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/layers.dart';
import 'package:flame_and_watch/game/cartridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlameWatchGame extends Game with KeyboardEvents {
  static Paint _backgroundPaint = Paint()..color = const Color(0xFF8D9E8C);
  static const GAME_RESOLUTION = const Size(128, 96);
  static Rect gameRect =
      Rect.fromLTWH(0, 0, GAME_RESOLUTION.width, GAME_RESOLUTION.height);

  FlameWatchGameController _controller;
  Timer _ticker;

  _BackgroundLayer _backgroundLayer;
  _GameLayer _gameLayer;
  Map<String, Sprite> _loadedSprites = {};

  double _gameScale;
  double _offset;

  Rect _screenRect;

  static Future<FlameWatchGame> load(
    Size gameSize,
    FlameWatchGameCartridge gameCartridge,
    FlameWatchGameController controller,
  ) async {
    final game = FlameWatchGame()
      .._screenRect = Rect.fromLTWH(0, 0, gameSize.width, gameSize.height)
      .._controller = controller;

    final spriteLoading = gameCartridge.sprites.entries.map((entry) {
      return Flame.images.fromBase64(entry.key, entry.value).then((image) {
        game._loadedSprites[entry.key] = Sprite(image);
      });
    }).toList();
    await Future.wait(spriteLoading);

    game._gameLayer = _GameLayer(
      game._loadedSprites,
      gameCartridge,
      controller,
    );

    final _backgroundImage = await Flame.images.fromBase64(
      '${gameCartridge.gameName}-background-image',
      gameCartridge.background,
    );
    game._backgroundLayer = _BackgroundLayer(Sprite(_backgroundImage));

    final scaleRaw = min(
      gameSize.height / GAME_RESOLUTION.height,
      gameSize.width / GAME_RESOLUTION.width,
    );

    game._gameScale = scaleRaw - scaleRaw % 0.02;
    game._offset =
        (gameSize.width - GAME_RESOLUTION.width * game._gameScale) / 2;
    game._ticker =
        Timer(gameCartridge.tickTime, repeat: true, onTick: game._tick)
          ..start();

    return game;
  }

  @override
  KeyEventResult onKeyEvent(event, keysPressed) {
    if (event is RawKeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        onLeft();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        onRight();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void update(double dt) {
    _ticker.update(dt);
  }

  void _tick() {
    _controller.onTick();
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.drawRect(_screenRect, _backgroundPaint);
    canvas.translate(_offset, 0);
    canvas.scale(_gameScale, _gameScale);

    canvas.clipRect(gameRect);
    _backgroundLayer.render(canvas);
    _gameLayer.render(canvas);
    canvas.restore();
  }

  void onLeft() {
    _controller.onLeft();
  }

  void onRight() {
    _controller.onRight();
  }
}

class _BackgroundLayer extends PreRenderedLayer {
  Sprite background;

  _BackgroundLayer(this.background) {
    preProcessors.add(
      ShadowProcessor(
        offset: Offset(1, 1),
        color: const Color(0xFFFFFFFF),
        opacity: 0.2,
      ),
    );
  }

  @override
  void drawLayer() {
    background.render(canvas, position: Vector2(0, 0));
  }
}

class _GameLayer extends DynamicLayer {
  Map<String, Sprite> sprites;
  FlameWatchGameCartridge cartridge;
  FlameWatchGameController controller;

  final TextPaint _smallDigitalFont = TextPaint(
      style: const TextStyle(
    fontSize: 14,
    color: const Color(0xFF000000),
    fontFamily: 'Crystal',
  ));

  final TextPaint _mediumDigitalFont = TextPaint(
      style: const TextStyle(
    fontSize: 18,
    color: const Color(0xFF000000),
    fontFamily: 'Crystal',
  ));

  final TextPaint _bigDigitalFont = TextPaint(
      style: const TextStyle(
    fontSize: 22,
    color: const Color(0xFF000000),
    fontFamily: 'Crystal',
  ));

  _GameLayer(this.sprites, this.cartridge, this.controller) {
    preProcessors.add(
      ShadowProcessor(
        offset: Offset(2, 2),
        opacity: 0.2,
      ),
    );
  }

  @override
  void drawLayer() {
    cartridge.digitalDisplays.values.forEach((display) {
      final textConfig = display.size == GameDigitalDisplaySize.SMALL
          ? _smallDigitalFont
          : display.size == GameDigitalDisplaySize.MEDIUM
              ? _mediumDigitalFont
              : _bigDigitalFont;

      textConfig.render(
        canvas,
        display.text,
        display.position,
      );
    });

    cartridge.gameSprites.forEach((gameSprite) {
      if (gameSprite.active) {
        final pos = Vector2(gameSprite.x, gameSprite.y);
        sprites[gameSprite.spriteName].render(
          canvas,
          position: pos,
        );
      }
    });
  }
}
