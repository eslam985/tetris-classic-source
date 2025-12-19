import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'tetromino.dart';
import 'audio_manager.dart';

class TetrisGame extends FlameGame with KeyboardEvents, TapCallbacks {
  Vector2 gameOffset = Vector2.zero();
  VoidCallback? onGameStateChanged;
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
// عرف الفرشة دي مرة واحدة فوق
  final Paint _clearEffectPaint = Paint()..style = PaintingStyle.fill;
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

  // تعريف أدوات الرسم مرة واحدة فقط لتوفير الذاكرة
  final Paint _cellPaint = Paint();
  final Paint _cellBorderPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  final Paint _highlightPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.2)
    ..style = PaintingStyle.fill;

  @override
  Color backgroundColor() => const Color(0xFF1a1a2e);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await AudioManager.loadSounds(); // تحميل الأصوات
    initializeGrid();
    generateNewPiece();
    _calculateBoardSize();
    AudioManager.playBackgroundMusic(); // تشغيل موسيقى الخلفية
  }

  void _calculateBoardSize() {
    // هوامش صغيرة جداً عشان ندي مساحة للعبة تكبر
    const double verticalPadding = 60.0;
    const double horizontalPadding = 20.0;

    final availableWidth = size.x - horizontalPadding;
    final availableHeight = size.y - verticalPadding;

    cellSize = min(availableWidth / gridWidth, availableHeight / gridHeight);
    boardSize = Vector2(gridWidth * cellSize, gridHeight * cellSize);

    boardStartX = (size.x - boardSize.x) / 2;

    // نرفعها 30 بكسل بس عن المركز
    boardStartY = (size.y - boardSize.y) / 2 - 30;

    if (boardStartY < 5) boardStartY = 5;
    gameOffset = Vector2(boardStartX, boardStartY);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    if (size.x > 0 && size.y > 0) {
      // السطر ده لوحده كفاية جداً لأنه بينادي على الدالة اللي فيها الحسابات الجديدة
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
        // امسح السطر اللي بيعمل setState هنا لو مش ضروري
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
    if (boardSize.x == 0) _calculateBoardSize();

    canvas.save();
    canvas.translate(gameOffset.x, gameOffset.y);

    // 1. رسم الخلفية مرة واحدة
    canvas.drawRect(
        Rect.fromLTWH(0, 0, boardSize.x, boardSize.y), backgroundPaint);

    // 2. رسم الإطار الخارجي (مهم جداً للرؤية)
    canvas.drawRect(Rect.fromLTWH(0, 0, boardSize.x, boardSize.y), borderPaint);

    // 3. تحسين رسم المربعات المستقرة (رسم المشغول فقط)
    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        if (grid[y][x] != 0) {
          // لو الخانة فيها مكعب فعلاً ارسمه
          _drawCell(canvas, x, y, grid[y][x]);
        }
      }
    }

    // 4. رسم القطعة اللي بتتحرك دلوقتي
    if (currentPiece != null) {
      currentPiece!.render(canvas, 0, 0, cellSize);
    }

    if (isAnimating) {
      _drawLineClearAnimation(canvas);
    }

    canvas.restore();

    // 5. رسم نصوص الحالة
    if (isGameOver) {
      _drawCenteredText(
          canvas, "GAME OVER", 32, Colors.redAccent, size.x / 2, size.y / 2);
    }
  }

  void _drawCell(Canvas canvas, int x, int y, int type) {
    final cellX = x * cellSize;
    final cellY = y * cellSize;

    // بنغير اللون بس في الأداة اللي عرفناها فوق بدل ما ننشئ واحدة جديدة
    _cellPaint.color = Tetromino.getColor(type);

    final rect =
        Rect.fromLTWH(cellX + 0.5, cellY + 0.5, cellSize - 1, cellSize - 1);

    // 1. رسم جسم المربع
    canvas.drawRect(rect, _cellPaint);

    // 2. رسم الإطار الأسود (باستخدام الأداة الجاهزة)
    canvas.drawRect(rect, _cellBorderPaint);

    // 3. رسم تأثير الإضاءة (Highlight)
    canvas.drawRect(
        Rect.fromLTWH(cellX + 2, cellY + 2, cellSize - 6, 2), _highlightPaint);
    canvas.drawRect(
        Rect.fromLTWH(cellX + 2, cellY + 2, 2, cellSize - 6), _highlightPaint);
  }

  void _drawLineClearAnimation(Canvas canvas) {
    final animationProgress = min(1.0, clearAnimationTime / 0.5);

    // بدل ما نكريه Object جديد، بنعدل لون الفرشة اللي عرفناها فوق
    _clearEffectPaint.color =
        Colors.white.withValues(alpha: 0.7 * (1 - animationProgress));

    for (final line in linesToClear) {
      final y = line * cellSize;
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          y,
          gridWidth * cellSize,
          cellSize * animationProgress,
        ),
        _clearEffectPaint, // استخدم الفرشة الجاهزة
      );
    }
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    double fontSize,
    Color color,
    double x,
    double y,
  ) {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          blurRadius: 4,
          color: Colors.black.withValues(alpha: 0.8),
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
    grid = List.generate(gridHeight, (_) => List.generate(gridWidth, (_) => 0));
  }

  void generateNewPiece() {
    // 1. املأ قطعة الانتظار لو فاضية
    nextPiece ??= Tetromino.getRandom();

    // 2. القطعة الحالية تاخد النسخة اللي عليها الدور وتبدأ من فوق
    currentPiece = nextPiece!.copyWith(x: gridWidth ~/ 2 - 1, y: 0);

    // 3. ولّد القطعة اللي جاية (Next Piece) في الكاش
    nextPiece = Tetromino.getRandom();

    // 4. تشيك الخسارة (Game Over)
    if (currentPiece != null && !isValidPosition(currentPiece!)) {
      isGameOver = true;
      AudioManager.playGameOver();
    }

    // 5. التحديث هنا مهم جداً عشان الـ UI يعرف إن الـ Next Piece اتغيرت
    // بس تأكد إن الـ Callback ده مبيعملش عمليات حسابية تقيلة
    onGameStateChanged?.call();
  }

  bool isValidPosition(Tetromino piece) {
    // 1. استخراج الـ blocks في متغير محلي عشان نوفر الوصول المتكرر للـ Object
    final blocks = piece.blocks;
    final px = piece.x;
    final py = piece.y;

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final gx = px + block.dx;
      final gy = py + block.dy;

      // 2. التحقق من الحدود (أسرع عملية رفض)
      if (gx < 0 || gx >= gridWidth || gy >= gridHeight) {
        return false;
      }

      // 3. التحقق من التصادم مع المكعبات المستقرة (فقط لو القطعة جوه حدود الـ Grid الطولية)
      if (gy >= 0 && grid[gy][gx] != 0) {
        return false;
      }
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
    // 1. تثبيت المتغيرات محلياً (أسرع بكتير من مناداة الـ Object كل شوية)
    final piece = currentPiece;
    if (piece == null) return;

    final px = piece.x;
    final py = piece.y;
    final blocks = piece.blocks;
    final type = piece.type;

    // 2. تحديث الشبكة (Grid) بأقل مجهود
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final gx = px + block.dx;
      final gy = py + block.dy;

      if (gy >= 0 && gy < gridHeight && gx >= 0 && gx < gridWidth) {
        grid[gy][gx] = type;
      }
    }

    // 3. الصوت يشتغل "في الخلفية"
    AudioManager.playDrop();

    // 4. الحسابات التقيلة (المسح وتوليد قطعة جديدة)
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
    int numLines = linesToClear.length;
    linesCleared += numLines;

    linesToClear.sort();

    for (final line in linesToClear.reversed) {
      grid.removeAt(line);
      grid.insert(0, List.generate(gridWidth, (_) => 0));
    }

    if (numLines > 0) {
      AudioManager.playLineClear();
      score += _calculateScore(numLines);
      level = 1 + (linesCleared ~/ 5);
      // السرعة بتبدأ أبطأ (1.0) وبتزيد ببطء شديد جداً (0.05)
      fallSpeed = max(0.5, 1.0 - (level - 1) * 0.05);

      // في دالة moveDown أو الـ Update
      if (timeSinceLastFall >= fallSpeed) {
        moveDown();
        timeSinceLastFall = 0;
        // شيل onGameStateChanged من هنا لو كانت موجودة
      }
    }

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
    AudioManager.playBackgroundMusic(); // إعادة تشغيل الموسيقى
  }

  void pauseGame() {
    isPaused = true;
    AudioManager.stopBackgroundMusic(); // إيقاف الموسيقى عند الإيقاف
  }

  void resumeGame() {
    isPaused = false;
    AudioManager.playBackgroundMusic(); // استئناف الموسيقى
  }

  void moveLeft() {
    if (isGameOver || isPaused || currentPiece == null) return;

    final newPiece = currentPiece!.copyWith(x: currentPiece!.x - 1);
    if (isValidPosition(newPiece)) {
      currentPiece = newPiece;
      // نادِ الصوت بدون await وبدون ما تشغل بالك بالنتيجة
      AudioManager.playMove();
    }
  }

  void moveRight() {
    if (isGameOver || isPaused || currentPiece == null) return;

    final newPiece = currentPiece!.copyWith(x: currentPiece!.x + 1);
    if (isValidPosition(newPiece)) {
      currentPiece = newPiece;
      AudioManager.playMove();
    }
  }

  void rotate() {
    if (isGameOver || isPaused || currentPiece == null) return;

    // 1. حساب الوضع الجديد
    final newPiece = currentPiece!.copyWith(
      rotation: (currentPiece!.rotation + 1) % 4,
    );

    // 2. تجربة الـ Wall Kicks (لو getWallKicks بترجع قائمة ثابتة يبقي تمام)
    final kicks = newPiece.getWallKicks();

    for (int i = 0; i < kicks.length; i++) {
      final kick = kicks[i];
      final kickedPiece = newPiece.copyWith(
        x: newPiece.x + kick.x,
        y: newPiece.y + kick.y,
      );

      if (isValidPosition(kickedPiece)) {
        currentPiece = kickedPiece;

        // 3. استدعاء الصوت بدون انتظار (Fire and Forget)
        AudioManager.playRotate();
        return;
      }
    }
  }

  void hardDrop() {
    if (isGameOver || isPaused || currentPiece == null) return;

    int dropDistance = 0; // عرفناه هنا

    while (true) {
      final newPiece = currentPiece!.copyWith(y: currentPiece!.y + 1);
      if (isValidPosition(newPiece)) {
        currentPiece = newPiece;
        dropDistance++; // زودناه هنا
      } else {
        break;
      }
    }

    // استخدمه هنا عشان تشيل الـ Warning وتدي سكور إضافي
    if (dropDistance > 0) {
      score += dropDistance * 2; // اللاعب ياخد نقطتين عن كل بلاطة نزلها بسرعة
    }

    lockPiece();
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
