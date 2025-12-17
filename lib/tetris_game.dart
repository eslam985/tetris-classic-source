import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'tetromino.dart';
import 'audio_manager.dart';  // أضف هذا الاستيراد

class TetrisGame extends FlameGame with KeyboardEvents, TapCallbacks, HasCollisionDetection {
  static const int gridWidth = 10;
  static const int gridHeight = 20;
  double cellSize = 32.0;
  double boardPadding = 10.0;
  
  late Vector2 boardSize;
  late double boardStartX;
  late double boardStartY;

  late List<List<int>> grid;
  Tetromino? currentPiece;
  Tetromino? nextPiece;
  int score = 0;
  int linesCleared = 0;
  int level = 1;
  double fallSpeed = 0.8;
  double timeSinceLastFall = 0;
  bool isGameOver = false;
  bool isPaused = false;
  
  List<int> linesToClear = [];
  double clearAnimationTime = 0;
  bool isAnimating = false;
  
  final Paint gridPaint = Paint()
    ..color = Colors.white24
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  
  final Paint backgroundPaint = Paint()
    ..color = const Color(0xFF121212)
    ..style = PaintingStyle.fill;
  
  final Paint borderPaint = Paint()
    ..color = const Color(0xFF00BCD4)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;

  @override
  Color backgroundColor() => const Color(0xFF1a1a2e);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await AudioManager.loadSounds();  // تحميل الأصوات
    initializeGrid();
    generateNewPiece();
    _calculateBoardSize();
    AudioManager.playBackgroundMusic();  // تشغيل موسيقى الخلفية
  }

  void _calculateBoardSize() {
    final availableWidth = size.x - (boardPadding * 2);
    final availableHeight = size.y - (boardPadding * 2);
    
    final cellSizeBasedOnWidth = availableWidth / gridWidth;
    final cellSizeBasedOnHeight = availableHeight / gridHeight;
    
    cellSize = min(cellSizeBasedOnWidth, cellSizeBasedOnHeight) * 0.98;
    
    boardSize = Vector2(gridWidth * cellSize, gridHeight * cellSize);
    boardStartX = (size.x - boardSize.x) / 2;
    boardStartY = (size.y - boardSize.y) / 2;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x > 0 && size.y > 0) {
      _calculateBoardSize();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isGameOver || isPaused || currentPiece == null) return;

    if (isAnimating) {
      clearAnimationTime += dt;
      if (clearAnimationTime >= 0.5) {
        _performLineClear();
        isAnimating = false;
        clearAnimationTime = 0;
      }
      return;
    }

    timeSinceLastFall += dt;
    if (timeSinceLastFall >= fallSpeed) {
      moveDown();
      timeSinceLastFall = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    if (boardSize.x == 0) {
      _calculateBoardSize();
    }
    
    canvas.drawRect(
      Rect.fromLTWH(boardStartX, boardStartY, boardSize.x, boardSize.y),
      backgroundPaint,
    );

    for (int i = 0; i <= gridWidth; i++) {
      final x = boardStartX + i * cellSize;
      canvas.drawLine(
        Offset(x, boardStartY),
        Offset(x, boardStartY + boardSize.y),
        gridPaint,
      );
    }
    
    for (int i = 0; i <= gridHeight; i++) {
      final y = boardStartY + i * cellSize;
      canvas.drawLine(
        Offset(boardStartX, y),
        Offset(boardStartX + boardSize.x, y),
        gridPaint,
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(boardStartX, boardStartY, boardSize.x, boardSize.y),
      borderPaint,
    );

    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        if (grid[y][x] != 0) {
          _drawCell(canvas, x, y, grid[y][x]);
        }
      }
    }

    if (currentPiece != null) {
      currentPiece!.render(canvas, boardStartX, boardStartY, cellSize);
    }

    if (isAnimating) {
      _drawLineClearAnimation(canvas);
    }

    if (isGameOver) {
      _drawCenteredText(
        canvas,
        "GAME OVER",
        32,
        Colors.redAccent,
        size.x / 2,
        size.y / 2,
      );
      _drawCenteredText(
        canvas,
        "Tap to restart",
        18,
        Colors.white70,
        size.x / 2,
        size.y / 2 + 40,
      );
    } else if (isPaused) {
      _drawCenteredText(
        canvas,
        "PAUSED",
        32,
        Colors.yellow,
        size.x / 2,
        size.y / 2,
      );
    }
  }

  void _drawCell(Canvas canvas, int x, int y, int type) {
    final cellX = boardStartX + x * cellSize;
    final cellY = boardStartY + y * cellSize;
    
    final color = Tetromino.getColor(type);
    final cellPaint = Paint()..color = color;
    
    canvas.drawRect(
      Rect.fromLTWH(cellX + 0.5, cellY + 0.5, cellSize - 1, cellSize - 1),
      cellPaint,
    );
    
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(
      Rect.fromLTWH(cellX + 0.5, cellY + 0.5, cellSize - 1, cellSize - 1),
      borderPaint,
    );
    
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(cellX + 2, cellY + 2, cellSize - 6, 2),
      highlightPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(cellX + 2, cellY + 2, 2, cellSize - 6),
      highlightPaint,
    );
  }

  void _drawLineClearAnimation(Canvas canvas) {
    final animationProgress = min(1.0, clearAnimationTime / 0.5);
    final animationPaint = Paint()
      ..color = Colors.white.withOpacity(0.7 * (1 - animationProgress))
      ..style = PaintingStyle.fill;
    
    for (final line in linesToClear) {
      final y = boardStartY + line * cellSize;
      canvas.drawRect(
        Rect.fromLTWH(
          boardStartX,
          y,
          gridWidth * cellSize,
          cellSize * animationProgress,
        ),
        animationPaint,
      );
    }
  }

  void _drawCenteredText(Canvas canvas, String text, double fontSize, Color color, double x, double y) {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          blurRadius: 4,
          color: Colors.black.withOpacity(0.8),
          offset: const Offset(2, 2),
        ),
      ],
    );
    
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  void initializeGrid() {
    grid = List.generate(
      gridHeight,
      (_) => List.generate(gridWidth, (_) => 0),
    );
  }

  void generateNewPiece() {
    nextPiece ??= Tetromino.getRandom();
    currentPiece = nextPiece?.copyWith(
      x: gridWidth ~/ 2 - 1,
      y: 0,
    );
    nextPiece = Tetromino.getRandom();

    if (currentPiece != null && !isValidPosition(currentPiece!)) {
      isGameOver = true;
      AudioManager.playGameOver();  // صوت نهاية اللعبة
    }
  }

  bool isValidPosition(Tetromino piece) {
    for (final block in piece.blocks) {
      final gx = piece.x + block.dx;
      final gy = piece.y + block.dy;

      if (gx < 0 || gx >= gridWidth || gy >= gridHeight) return false;
      if (gy >= 0 && grid[gy][gx] != 0) return false;
    }
    return true;
  }

  void moveDown() {
    if (isGameOver || isPaused || currentPiece == null) return;

    final newPiece = currentPiece!.copyWith(y: currentPiece!.y + 1);

    if (isValidPosition(newPiece)) {
      currentPiece = newPiece;
    } else {
      lockPiece();
    }
  }

  void lockPiece() {
    if (currentPiece == null) return;
    
    AudioManager.playDrop();  // صوت تثبيت القطعة
    
    for (final block in currentPiece!.blocks) {
      final gx = currentPiece!.x + block.dx;
      final gy = currentPiece!.y + block.dy;
      
      if (gy >= 0 && gy < gridHeight && gx >= 0 && gx < gridWidth) {
        grid[gy][gx] = currentPiece!.type;
      }
    }
    
    checkLines();
    generateNewPiece();
  }

  void checkLines() {
    linesToClear.clear();
    
    for (int y = gridHeight - 1; y >= 0; y--) {
      if (grid[y].every((cell) => cell != 0)) {
        linesToClear.add(y);
      }
    }
    
    if (linesToClear.isNotEmpty) {
      isAnimating = true;
      clearAnimationTime = 0;
    }
  }

  void _performLineClear() {
    linesCleared += linesToClear.length;
    
    linesToClear.sort();
    
    for (final line in linesToClear.reversed) {
      grid.removeAt(line);
      grid.insert(0, List.generate(gridWidth, (_) => 0));
    }
    
    if (linesToClear.isNotEmpty) {
      AudioManager.playLineClear();  // صوت مسح الخط
    }
    
    score += _calculateScore(linesToClear.length);
    
    level = 1 + (linesCleared ~/ 10);
    fallSpeed = max(0.1, 0.8 - (level - 1) * 0.05);
    
    linesToClear.clear();
  }

  int _calculateScore(int lines) {
    const lineScores = [0, 100, 300, 500, 800];
    return (lineScores[lines] * level);
  }

  void startGame() {
    initializeGrid();
    score = 0;
    linesCleared = 0;
    level = 1;
    fallSpeed = 0.8;
    isGameOver = false;
    isPaused = false;
    isAnimating = false;
    generateNewPiece();
    AudioManager.playBackgroundMusic();  // إعادة تشغيل الموسيقى
  }

  void pauseGame() {
    isPaused = true;
    AudioManager.stopBackgroundMusic();  // إيقاف الموسيقى عند الإيقاف
  }

  void resumeGame() {
    isPaused = false;
    AudioManager.playBackgroundMusic();  // استئناف الموسيقى
  }

  void moveLeft() {
    if (isGameOver || isPaused || currentPiece == null) return;
    final newPiece = currentPiece!.copyWith(x: currentPiece!.x - 1);
    if (isValidPosition(newPiece)) {
      currentPiece = newPiece;
      AudioManager.playMove();  // صوت الحركة
    }
  }

  void moveRight() {
    if (isGameOver || isPaused || currentPiece == null) return;
    final newPiece = currentPiece!.copyWith(x: currentPiece!.x + 1);
    if (isValidPosition(newPiece)) {
      currentPiece = newPiece;
      AudioManager.playMove();  // صوت الحركة
    }
  }

  void rotate() {
    if (isGameOver || isPaused || currentPiece == null) return;
    
    final newPiece = currentPiece!.copyWith(
      rotation: (currentPiece!.rotation + 1) % 4,
    );
    
    for (final kick in newPiece.getWallKicks()) {
      final kickedPiece = newPiece.copyWith(
        x: newPiece.x + kick.x,
        y: newPiece.y + kick.y,
      );
      
      if (isValidPosition(kickedPiece)) {
        currentPiece = kickedPiece;
        AudioManager.playRotate();  // صوت الدوران
        return;
      }
    }
  }

  void hardDrop() {
    if (isGameOver || isPaused || currentPiece == null) return;
    
    while (true) {
      final newPiece = currentPiece!.copyWith(y: currentPiece!.y + 1);
      if (isValidPosition(newPiece)) {
        currentPiece = newPiece;
      } else {
        lockPiece();
        break;
      }
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        moveLeft();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        moveRight();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        moveDown();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        rotate();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.space) {
        hardDrop();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyP) {
        isPaused = !isPaused;
        if (isPaused) {
          pauseGame();
        } else {
          resumeGame();
        }
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyR) {
        startGame();
        return KeyEventResult.handled;
      }
    }
    
    return KeyEventResult.ignored;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) {
      startGame();
      return;
    }
    
    if (isPaused || isAnimating) return;
    
    final tapX = event.localPosition.x;
    final boardEndX = boardStartX + boardSize.x;
    
    if (tapX < boardStartX || tapX > boardEndX) return;
    
    final relativeX = tapX - boardStartX;
    if (relativeX < boardSize.x / 3) {
      moveLeft();
    } else if (relativeX > boardSize.x * 2 / 3) {
      moveRight();
    } else {
      rotate();
    }
  }
}