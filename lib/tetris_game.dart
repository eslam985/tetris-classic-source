import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'tetromino.dart';
import 'audio_manager.dart';

class TetrisGame extends FlameGame
    with KeyboardEvents, TapCallbacks, ChangeNotifier {
  Vector2 gameOffset = Vector2.zero();

  // 1. التعديل الجوهري: استبدال الـ Callback والـ variables العادية بـ Notifiers
  // دي بتسمح لـ Flutter إنه يحدّث السكور أو القطعة الجاية بس من غير ما يهد اللعبة كلها
  final scoreNotifier = ValueNotifier<int>(0);
  final nextPieceNotifier = ValueNotifier<Tetromino?>(null);
  final levelNotifier = ValueNotifier<int>(1);
  final gameOverNotifier = ValueNotifier<bool>(false);

  static const int gridWidth = 10;
  static const int gridHeight = 20;
  double cellSize = 32.0;
  double boardPadding = 10.0;

  late Vector2 boardSize;
  late double boardStartX;
  late double boardStartY;

  late List<List<int>> grid;
  Tetromino? currentPiece;

  // شيلنا الـ nextPiece العادية وخليناها تعتمد على الـ Notifier
  Tetromino? get nextPiece => nextPieceNotifier.value;
  set nextPiece(Tetromino? value) => nextPieceNotifier.value = value;

  // السكور والفل بيتحكم فيهم الـ Notifier دلوقتي للأداء الأقصى
  int get score => scoreNotifier.value;
  set score(int value) => scoreNotifier.value = value;

  int get level => levelNotifier.value;
  set level(int value) => levelNotifier.value = value;

  bool get isGameOver => gameOverNotifier.value;
  set isGameOver(bool value) => gameOverNotifier.value = value;

  int linesCleared = 0;
  double fallSpeed = 1.0;
  double timeSinceLastFall = 0;
  bool isPaused = false;

  List<int> linesToClear = [];
  double clearAnimationTime = 0;
  bool isAnimating = false;

  // 2. أدوات الرسم (متازة كما هي، متعرفة مرة واحدة)
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

  final Paint _cellPaint = Paint();
  final Paint _cellBorderPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  final Paint _highlightPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.2)
    ..style = PaintingStyle.fill;

  int getGhostY() {
    if (currentPiece == null) return 0;

    // بنبدأ من مكان القطعة الحالي
    int ghostY = currentPiece!.y;

    // بنجرب ننزل لتحت وهمياً باستخدام testY
    // طول ما المكان اللي تحتنا (ghostY + 1) فاضي، بنزود الـ ghostY
    while (isValidPosition(currentPiece!,
        testX: currentPiece!.x, testY: ghostY + 1)) {
      ghostY++;
    }

    return ghostY;
  }

  @override
  Color backgroundColor() => const Color(0xFF1a1a2e);
  @override
  Future<void> onLoad() async {
    // 1. استدعاء الـ super أول حاجة (صح)
    await super.onLoad();

    // 2. تحميل الأصوات (أهم خطوة ومكانها صح)
    // بس اتأكد إن الـ loadSounds جواها الـ AudioPool اللي اتفقنا عليه
    await AudioManager.loadSounds();

    // 3. تهيئة البيانات (عمليات سريعة في الذاكرة)
    initializeGrid();
    generateNewPiece();
    _calculateBoardSize();

    // 4. تشغيل المزيكا (آخر حاجة بعد ما نضمن إن كل الملفات في الـ Cache)
    AudioManager.playBackgroundMusic();
  }

  void _calculateBoardSize() {
    // 1. هوامش أمان بسيطة جداً (أقل ما يمكن) عشان اللعبة تاخد حيزها
    const double horizontalMargin = 10.0;
    const double verticalMargin = 20.0;

    // 2. حساب المساحة الفعلية المتاحة
    final availableWidth = size.x - horizontalMargin;
    final availableHeight = size.y - verticalMargin;

    // 3. السطر ده هو أهم سطر.. الـ cellSize هياخد أكبر قيمة ممكنة
    // بحيث يملأ إما عرض الشاشة أو طولها بالكامل
    cellSize = min(availableWidth / gridWidth, availableHeight / gridHeight);

    // 4. تحديد حجم اللوحة بناءً على الـ cellSize الجديد
    boardSize = Vector2(gridWidth * cellSize, gridHeight * cellSize);

    // 5. التوسطن العبقري (Mathematical Centering)
    // بنطرح حجم اللعبة من حجم الشاشة ونقسم على 2.. كدة مستحيل تترحل بكسل واحد
    boardStartX = (size.x - boardSize.x) / 2;
    boardStartY = (size.y - boardSize.y) / 2;

    // 6. تحديث الـ Offset النهائي
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

    // 1. الحماية الأساسية
    if (isGameOver || isPaused || currentPiece == null) return;

    // 2. معالجة الأنميشن (المسح)
    if (isAnimating) {
      clearAnimationTime += dt;
      if (clearAnimationTime >= 0.3) {
        // أهم خطوة: المسح لازم يتم "خارج" الفريم اللي فيه حركة
        _performLineClear();
        isAnimating = false;
        clearAnimationTime = 0;
        timeSinceLastFall =
            0; // "صفر" عداد الحركة عشان القطعة ما تنطش فجأة بعد المسح
      }
      return; // هنا الـ return ضرورية جداً عشان المعالج يركز في الأنميشن بس
    }

    // 3. حركة القطعة (Physics)
    timeSinceLastFall += dt;

    // الحقيقة الصارمة: تحديد حد أقصى للـ while
    // عشان لو الجهاز هنج دقيقة ما يحاولش ينفذ 1000 حركة في فريم واحد
    int safetyCounter = 0;
    while (timeSinceLastFall >= fallSpeed && safetyCounter < 3) {
      moveDown();
      timeSinceLastFall -= fallSpeed;
      safetyCounter++;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (boardSize.x == 0) {
      _calculateBoardSize();
    }

    // --- السطر السحري هنا ---
    // ده بيخلي الـ Canvas يبدأ يرسم من الـ Offset اللي حسبناه (اللي فيه الـ 120 بكسل فرق)
    canvas.save();
    canvas.translate(gameOffset.x, gameOffset.y);
    // الآن كل الرسم اللي تحت هيترسم "نسبةً" للنقطة الجديدة
    // ملحوظة: لازم نستبدل boardStartX و boardStartY بـ 0
    // لأن الـ translate هي اللي قامت بالمهمة دي خلاص

    // 1. رسم الخلفية
    canvas.drawRect(
      Rect.fromLTWH(0, 0, boardSize.x, boardSize.y),
      backgroundPaint,
    );

    // 2. رسم خطوط الشبكة الطولية
    for (int i = 0; i <= gridWidth; i++) {
      final x = i * cellSize;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, boardSize.y),
        gridPaint,
      );
    }

    // 3. رسم خطوط الشبكة العرضية
    for (int i = 0; i <= gridHeight; i++) {
      final y = i * cellSize;
      canvas.drawLine(
        Offset(0, y),
        Offset(boardSize.x, y),
        gridPaint,
      );
    }

    // 4. رسم الإطار الخارجي
    canvas.drawRect(
      Rect.fromLTWH(0, 0, boardSize.x, boardSize.y),
      borderPaint,
    );

    // 5. رسم المربعات المستقرة (Grid)
    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        if (grid[y][x] != 0) {
          _drawCell(canvas, x, y, grid[y][x]);
        }
      }
    }

    // 6. رسم القطعة الحالية (عدلنا الـ parameters لـ 0,0)
    if (currentPiece != null) {
      currentPiece!.render(canvas, 0, 0, cellSize);
    }

    if (isAnimating) {
      _drawLineClearAnimation(canvas);
    }

    canvas
        .restore(); // بنرجع الـ canvas لحالته الطبيعية عشان نكتب التكست في نص الشاشة الحقيقي

    // 7. رسم نصوص الحالة (تفضل في نص الشاشة الكلي)
    if (isGameOver) {
      _drawCenteredText(
          canvas, "GAME OVER", 32, Colors.redAccent, size.x / 2, size.y / 2);
      _drawCenteredText(canvas, "Tap to restart", 18, Colors.white70,
          size.x / 2, size.y / 2 + 40);
    } else if (isPaused) {
      _drawCenteredText(
          canvas, "PAUSED", 32, Colors.yellow, size.x / 2, size.y / 2);
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
    // 1. استخدام متغيرات محلية (شغل محترفين)
    final next = nextPiece ?? Tetromino.getRandom();

    // 2. تعيين القطعة الحالية
    currentPiece = next.copyWith(x: gridWidth ~/ 2 - 1, y: 0);

    // 3. توليد القطعة القادمة وتحديث الـ Notifier أوتوماتيكياً
    // الـ setter اللي عملناه في الكلاس هو اللي بيحدث الـ Notifier
    nextPiece = Tetromino.getRandom();

    // 4. تشيك الخسارة (Game Over)
    if (!isValidPosition(currentPiece!)) {
      isGameOver = true; // ده دلوقتى بيحدث الـ gameOverNotifier أوتوماتيك
      AudioManager.stopBackgroundMusic();
      AudioManager.playGameOver();
      return; // شيلنا الـ call القديم
    }

    // 5. التحديث بقى "تلقائي"
    // أول ما عملنا nextPiece = ... الـ UI عرفت لوحدها
    // مفيش داعي لمناداة onGameStateChanged خلاص
  }

  bool isValidPosition(Tetromino piece, {int? testX, int? testY}) {
    // 1. استخراج الـ blocks
    final blocks = piece.blocks;

    // السر هنا: لو بعتنا testX أو testY (في حالة الخيال) هنستخدمهم
    // لو مبعتناش (في حالة الحركة العادية) هنستخدم x و y بتوع القطعة
    final px = testX ?? piece.x;
    final py = testY ?? piece.y;

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final gx = px + block.dx.toInt(); // التأكد إنها int
      final gy = py + block.dy.toInt();

      // 2. التحقق من الحدود
      if (gx < 0 || gx >= gridWidth || gy >= gridHeight) {
        return false;
      }

      // 3. التحقق من التصادم مع المكعبات المستقرة
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
    final piece = currentPiece;
    if (piece == null) return;

    final px = piece.x;
    final py = piece.y;
    final blocks = piece.blocks;
    final type = piece.type;

    // 1. التثبيت في الـ Grid (عملية سريعة جداً)
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final gx = px + block.dx;
      final gy = py + block.dy;

      if (gy >= 0 && gy < gridHeight && gx >= 0 && gx < gridWidth) {
        grid[gy][gx] = type;
      }
    }

    // 2. الصوت (لازم يكون AudioPool عشان ميعملش لاج)
    AudioManager.playDrop();

    // 3. التحقق من السطور
    checkLines();

    // 4. "السر في السطر ده": توليد القطعة الجديدة
    // لو مفيش أنميشن مسح سطور، ولد القطعة الجديدة فوراً
    if (!isAnimating) {
      generateNewPiece();
    }
    // ملاحظة: لو فيه أنميشن، generateNewPiece المفروض تتنادى
    // بعد ما الأنميشن يخلص في دالة _performLineClear
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
    // لو مفيش صفوف مكتملة، اخرج فوراً وما تعملش حاجة
    if (linesToClear.isEmpty) return;

    int numLines = linesToClear.length;
    linesCleared += numLines;

    // 1. منطق المسح الذكي: بنفلتر الشبكة ونشيل الصفوف اللي رقمها موجود في قائمة المسح
    final newGrid = grid.indexed
        .where((entry) => !linesToClear.contains(entry.$1))
        .map((entry) => entry.$2)
        .toList();

    // 2. تعويض الصفوف: بنضيف صفوف فاضية (أصفار) في أعلى الشبكة بدل اللي اتمسحت
    while (newGrid.length < gridHeight) {
      newGrid.insert(0, List.generate(gridWidth, (_) => 0));
    }

    grid = newGrid;

    // 3. تحديث البيانات (هنا مربط الفرس للسكور)
    AudioManager.playLineClear(); // تشغيل صوت المسح

    // تحديث الـ Notifier مباشرة هو اللي بيجبر الـ UI يغير الرقم فوراً
    scoreNotifier.value += _calculateScore(numLines);

    // حساب المستوى الجديد: كل 5 صفوف بليفل جديد
    level = 1 + (linesCleared ~/ 5);

    // زيادة سرعة السقوط مع كل ليفل (بحد أدنى 0.4 ثانية)
    fallSpeed = max(0.4, 1.0 - (level - 1) * 0.05);

    // تنظيف قائمة الصفوف الممسوحة عشان نستعد للمرة الجاية
    linesToClear.clear();

    // السطر ده بيبعت إشارة لكل الـ Widgets إن "الحالة اتغيرت.. ارسموا نفسكم تاني"
    notifyListeners();

    // توليد قطعة جديدة تبدأ تنزل من فوق
    generateNewPiece();
  }

  int _calculateScore(int lines) {
    // 1. الحساب فقط (بدون تحديث متغيرات خارجية)
    if (lines <= 0) return 0;

    // السكور الأصلي لنظام نينتندو (Nintendo Scoring System)
    const lineScores = [0, 40, 100, 300, 1200];

    int baseScore = (lines < lineScores.length)
        ? lineScores[lines]
        : 2000; // لو مسح أكتر من 4 بضربة واحدة

    // 2. ترجيع القيمة فقط
    return baseScore * level;
  }

  void startGame() {
    initializeGrid();
    score = 0;
    linesCleared = 0;
    level = 1;
    fallSpeed = 1.0;
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

    int dropDistance = 0;

    // 1. حساب أقصى مسافة ممكنة بدون إنشاء Objects كتير
    // بنجرب ننزل لتحت لحد ما نخبط في حاجة
    while (isValidPosition(
        currentPiece!.copyWith(y: currentPiece!.y + dropDistance + 1))) {
      dropDistance++;
    }

    // 2. تحديث مكان القطعة "مرة واحدة" فقط
    if (dropDistance > 0) {
      currentPiece = currentPiece!.copyWith(y: currentPiece!.y + dropDistance);
      score += dropDistance * 2; // مكافأة الهارد دروب

      // 3. صوت الـ Drop لازم يشتغل هنا فوراً
      // عشان اللاعب يحس بقوة الـ Hard Drop
      AudioManager.playDrop();
    }

    // 4. التثبيت
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
