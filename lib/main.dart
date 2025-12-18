import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'tetris_game.dart';
import 'next_piece_display.dart';
import 'audio_manager.dart'; // أضف هذا الاستيراد
import 'dart:ui'; // السطر ده هو اللي هيعرف فلاتر يعني إيه ImageFilter

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tetris Classic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
      ),
      home: const TetrisHomePage(),
    );
  }
}

class TetrisHomePage extends StatefulWidget {
  const TetrisHomePage({super.key});

  @override
  State<TetrisHomePage> createState() => _TetrisHomePageState();
}

class _TetrisHomePageState extends State<TetrisHomePage> {
  bool _isGameRunning = false;
  bool _isPaused = false;
  bool _isMuted = false; // متغير جديد للصوت
  late TetrisGame _game;

  @override
  void initState() {
    super.initState();
    _game = TetrisGame();

    // تعديل السطر السحري عشان يمنع التقطيع (Lag) في أول جيم
    _game.onGameStateChanged = () {
      if (mounted) {
        // بنستخدم addPostFrameCallback عشان الـ setState تستنى الفريم اللي عليه الدور
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    };
  }

  void _startGame() {
    setState(() {
      _isGameRunning = true;
      _isPaused = false;
      _game.startGame();
    });
  }

  void _togglePause() {
    setState(() {
      if (_isGameRunning) {
        _isPaused = !_isPaused;
        _isPaused ? _game.pauseGame() : _game.resumeGame();
      }
    });
  }

  void _restartGame() {
    setState(() {
      _game = TetrisGame();
      // لازم نعيد الربط لما نكريت نسخة جديدة من اللعبة
      _game.onGameStateChanged = () {
        if (mounted) {
          // السطر ده بيخلي فلاتر ميعملش ريفريش غير لما الموبايل يكون جاهز فعلاً
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
        }
      };
      _isGameRunning = true;
      _isPaused = false;
      _game.startGame();
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      AudioManager.toggleMute();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: Padding(
          // التعديل هنا: بنضيف مساحة 40 بكسل من تحت عشان نرفع الكنترولات فوق التاسك بار
          padding: const EdgeInsets.only(bottom: 40),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;

              if (_isGameRunning) {
                if (screenWidth > 1000) {
                  return _buildWideDesktopLayout();
                } else if (screenWidth > 600) {
                  return _buildTabletLayout();
                } else {
                  return _buildMobileLayout();
                }
              } else {
                return _buildStartScreen();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'TETRIS',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'CLASSIC',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _startGame,
            icon: const Icon(Icons.play_arrow),
            label: const Text('START GAME'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
          ),
          const SizedBox(height: 30),
          IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              size: 36,
              color: Colors.white70,
            ),
            onPressed: _toggleMute,
          ),
        ],
      ),
    );
  }

  Widget _buildWideDesktopLayout() {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 260,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: const Color(0xFF1D1E33),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TETRIS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const Text(
                        'CLASSIC',
                        style: TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      _buildStatsSection(),
                      const SizedBox(height: 10),
                      // لفيتها بـ RepaintBoundary عشان نجبر فلاتر يرسمها لوحدها
                      RepaintBoundary(
                        child: _buildNextPieceSection(),
                      ),
                      const SizedBox(height: 10),
                      _buildControlsSection(),
                      const SizedBox(height: 15),
                      _buildInstructions(),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRect(
                      child: GameWidget(
                        game: _game,
                        loadingBuilder: (context) => Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    if (_isPaused) _buildPauseOverlay(),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 15,
          right: 15,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _toggleMute,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Stack(
      children: [
        Column(
          children: [
            // الجزء العلوي (Stats)
            Container(
              height: 70, // زودناه سنة عشان الراحة
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: const Color(0xFF1D1E33),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('SCORE', '${_game.score}'),
                  _buildStatCard('LEVEL', '${_game.level}'),
                  _buildStatCard('LINES', '${_game.linesCleared}'),
                ],
              ),
            ),

            // منطقة اللعبة
            Expanded(
              child: GameWidget(
                game: _game,
                loadingBuilder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              ),
            ),

            // الجزء السفلي (Next Piece + Controls)
            Container(
              // شيلنا الارتفاع الثابت أو خليناه MinHeight باستخدام Constraints
              constraints: const BoxConstraints(minHeight: 140, maxHeight: 180),
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1D1E33),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // لفينا الـ Next Piece بـ AspectRatio عشان نحافظ على شكل المربع
                  Expanded(
                      flex: 2,
                      child: AspectRatio(
                          aspectRatio: 1, child: _buildNextPieceSection())),
                  const SizedBox(width: 15),
                  // الـ Controls تاخد باقي المساحة
                  Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                          // أمان ضد الـ Overflow لو الزراير كتير
                          scrollDirection: Axis.vertical,
                          child: _buildControlsSection())),
                ],
              ),
            ),
          ],
        ),

        // زر كتم الصوت
        Positioned(
          top: 10,
          right: 10,
          child: IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
              size: 30,
            ),
            onPressed: _toggleMute,
          ),
        ),

        if (_isPaused) _buildPauseOverlay(),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: const Color(0xFF1D1E33),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildStatCard('SCORE', '${_game.score}'),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'NEXT',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 65,
                      height: 65,
                      padding: const EdgeInsets.all(8),
                      // جوه دالة _buildNextPieceSection
                      decoration: BoxDecoration(
                        color: const Color(0xFF24264D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: NextPieceDisplay(nextPiece: _game.nextPiece),
                        ),
                      ),
                    ),
                  ],
                ),
                _buildStatCard('LEVEL', '${_game.level}'),
              ],
            ),
          ),
        ),
        Expanded(
          child: RepaintBoundary(
            // الحل السحري هنا: بيعزل رسم منطقة اللعب عن باقي الشاشة
            child: Stack(
              children: [
                GameWidget(
                  game: _game,
                  // الـ key ده مهم جداً عشان فلاتر ميتلخبطش ويعيد بناء اللعبة من الصفر
                  key: const ValueKey('tetris_game_widget'),
                  loadingBuilder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                ),
                // الـ Overlay برضه لفيناه بـ RepaintBoundary عشان مياثرش على أداء اللعبة وهي شغالة
                if (_isPaused) RepaintBoundary(child: _buildPauseOverlay()),
              ],
            ),
          ),
        ),

        // تم إصلاح الـ Container السفلي هنا بإزالة const من الـ BoxDecoration والـ Shadow
        Container(
          padding: const EdgeInsets.only(bottom: 30, top: 15),
          decoration: BoxDecoration(
            // حذفنا const من هنا
            color: const Color(0xFF1D1E33),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCircleControl(
                Icons.rotate_right,
                () => _game.rotate(),
                Colors.orangeAccent,
                "Rotate",
                size: 65,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircleControl(
                    Icons.arrow_back,
                    () => _game.moveLeft(),
                    Colors.blueAccent,
                    "Left",
                    size: 65,
                  ),
                  _buildCircleControl(
                    Icons.keyboard_double_arrow_down,
                    () => _game.hardDrop(),
                    Colors.redAccent,
                    "DROP",
                    size: 75,
                  ),
                  _buildCircleControl(
                    Icons.arrow_forward,
                    () => _game.moveRight(),
                    Colors.blueAccent,
                    "Right",
                    size: 65,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      // استخدمنا الـ Width الـ infinity عشان نملأ الـ Sidebar بالكامل
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(15), // كيرف أنعم شوية
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.05)), // برواز خفي
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // بلاش Stretch عشان نتحكم في الهوامش
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard_rounded,
                  size: 16, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text(
                'STATS',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child:
                Divider(color: Colors.white10, height: 1), // فاصل بسيط للشياكة
          ),
          _buildStatRow(
              'SCORE', _game.score.toString().padLeft(6, '0')), // تنسيق الأرقام
          const SizedBox(height: 8),
          _buildStatRow('LINES', '${_game.linesCleared}'),
          const SizedBox(height: 8),
          _buildStatRow('LEVEL', '${_game.level}'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 2), // مسافة بسيطة بين الأسطر
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // الـ Title محمي بـ Flexible عشان لو الرقم زاد النص ميهنجش
          Flexible(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12, // نزلنا لـ 12 عشان نحافظ على الـ Hierarchy
                color: Colors.white54, // لون أهدى شوية للعنوان
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis, // لو العنوان طويل يتقص بنقط
            ),
          ),
          const SizedBox(width: 8), // فجوة أمان
          // الـ Value واخدة راحتها
          Text(
            value,
            style: const TextStyle(
              fontSize: 16, // نزلنا لـ 16 عشان تبقى متناسقة مع عرض الـ Sidebar
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier', // لو عندك خط Fixed-width يبقى أحسن للأرقام
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 2), // قللنا الـ vertical padding
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FittedBox(
        // ضفنا ده عشان يصغر النص لو المكان ضيق جداً
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // عشان مياخدش مساحة أكبر من اللي محتاجها
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
            // حذفنا الـ SizedBox أو قللناه جداً عشان نوفر بكسلات
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextPieceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12), // زودنا البادينج عشان الشكل يبقي أنضف
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'NEXT PIECE',
            style: TextStyle(
              fontSize: 12, // كبرنا الخط شوية طالما في مساحة
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          // هنا التعديل الجوهري:
          SizedBox(
            height: 80, // بدل 40.. الـ 80 بكسل مساحة ممتازة للرسم
            child: Center(
              child: AspectRatio(
                aspectRatio: 1, // بنجبر الرسمة تكون مربعة
                child: NextPieceDisplay(nextPiece: _game.nextPiece),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    return Container(
      width: double.infinity,
      // قللنا الـ vertical padding لـ 8 عشان نوفر مساحة للأخطاء اللي بتظهر
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CONTROLS',
            style: TextStyle(
              fontSize: 10, // صغرنا العنوان بكسل كمان
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8), // قللنا المسافة بين العنوان والزراير

          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // استخدمت FittedBox حول الزراير كحماية إضافية لو الشاشة بقت ميكروسكوبية
              _buildControlButton(
                icon: Icons.refresh,
                label: 'RESTART',
                onPressed: _restartGame,
                color: Colors.orange,
              ),
              _buildControlButton(
                icon: _isPaused ? Icons.play_arrow : Icons.pause,
                label: _isPaused ? 'RESUME' : 'PAUSE',
                onPressed: _togglePause,
                color: _isPaused ? Colors.green : Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Tooltip(
      message: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onPressed,
          child: Column(
            // الـ Column هنا جوه الـ GestureDetector عشان الاستجابة تكون أحسن
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                // صغرنا الدائرة من 48 لـ 36 عشان نوفر الـ 8 بكسل وأكتر
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4, // قللنا الـ blur عشان مياخدش مساحة وهمية
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(icon,
                    color: Colors.white, size: 18), // صغرنا الأيقونة لـ 18
              ),
              const SizedBox(height: 4), // قللنا المسافة من 6 لـ 4
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 9, // صغرنا الخط لـ 9
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      width: double.infinity, // نملأ العرض المتاح
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // مهم جداً لمنع التمدد الوهمي
        children: [
          Row(
            children: [
              Icon(Icons.keyboard_command_key_rounded,
                  size: 14, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text(
                'KEYBOARD',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(color: Colors.white10, height: 1),
          ),
          // استخدام Wrap أو Rows خفيفة
          _buildInstructionRow('← →', 'Move'),
          const SizedBox(height: 4),
          _buildInstructionRow('↑', 'Rotate'),
          const SizedBox(height: 4),
          _buildInstructionRow('↓', 'Soft Drop'),
          const SizedBox(height: 4),
          _buildInstructionRow('SPACE', 'Hard Drop'),
          const SizedBox(height: 4),
          _buildInstructionRow('P', 'Pause'),
        ],
      ),
    );
  }

  Widget _buildInstructionRow(String key, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // استخدام SizedBox بعرض ثابت للـ Key عشان الـ Actions كلها تبدأ من نفس النقطة
          SizedBox(
            width: 55, // عرض كافي لكلمة SPACE
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: Colors.white24, width: 0.5), // تأثير زراير الكيبورد
              ),
              child: Text(
                key,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9, // صغرنا سيكا عشان الكلمات الطويلة
                  fontWeight: FontWeight.bold,
                  fontFamily:
                      'monospace', // خطوط الكود بتليق جداً مع أزرار الكيبورد
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // استخدام Expanded عشان لو الـ Action طويل ميكسرش السطر
          Expanded(
            child: Text(
              action,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return BackdropFilter(
      // تأثير الزجاج المضبب (Blur) بيخلي شكل اللعبة ورا الـ Pause خرافة
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withValues(
            alpha: 0.5), // قللنا التعتيم عشان نشوف اللعبة ورا الـ Blur
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة نابضة (ممكن تحطها جوه TweenAnimationBuilder لو عايز حركة)
              Icon(
                Icons.pause_circle_filled_rounded,
                size: 80,
                color: Colors.yellow.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 20),
              Text(
                'GAME PAUSED',
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                        color: Colors.yellow.withValues(alpha: 0.5),
                        blurRadius: 15),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // زرار Resume بشكل أنظف
              SizedBox(
                width: 180,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _togglePause,
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: const Text(
                    'RESUME',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleControl(
    IconData icon,
    VoidCallback onTap,
    Color color,
    String label, {
    double size = 60,
  }) {
    return Column(
      children: [
        GestureDetector(
          // استخدمنا onTapDown عشان الاستجابة تكون فورية بمجرد اللمس
          onTapDown: (_) => onTap(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54)),
      ],
    );
  }
}
