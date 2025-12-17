import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'tetris_game.dart';
import 'next_piece_display.dart';
import 'audio_manager.dart'; // أضف هذا الاستيراد

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
              width: 300,
              padding: const EdgeInsets.all(25),
              color: const Color(0xFF1D1E33),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TETRIS',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const Text(
                        'CLASSIC',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildStatsSection(),
                  const SizedBox(height: 30),
                  _buildNextPieceSection(),
                  const SizedBox(height: 30),
                  _buildControlsSection(),
                  const Spacer(),
                  _buildInstructions(),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  GameWidget(
                    game: _game,
                    loadingBuilder: (context) => Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  if (_isPaused) _buildPauseOverlay(),
                ],
              ),
            ),
          ],
        ),

        // زر كتم الصوت
        Positioned(
          top: 10,
          left: 10,
          child: IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
              size: 30,
            ),
            onPressed: _toggleMute,
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
            Container(
              height: 60,
              padding: const EdgeInsets.all(10),
              color: const Color(0xFF1D1E33),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard('SCORE', '${_game.score}'),
                  _buildStatCard('LEVEL', '${_game.level}'),
                  _buildStatCard('LINES', '${_game.linesCleared}'),
                ],
              ),
            ),
            Expanded(
              flex: 7,
              child: Stack(
                children: [
                  GameWidget(
                    game: _game,
                    loadingBuilder: (context) => Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  if (_isPaused) _buildPauseOverlay(),
                ],
              ),
            ),
            Container(
              height: 120,
              padding: const EdgeInsets.all(10),
              color: const Color(0xFF1D1E33),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildNextPieceSection(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: _buildControlsSection(),
                  ),
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
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // 1. شريط علوي للإحصائيات وكتم الصوت
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: const Color(0xFF1D1E33),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white70),
                  onPressed: _toggleMute,
                ),
                _buildStatCard('SCORE', '${_game.score}'),
                _buildStatCard('LEVEL', '${_game.level}'),
                IconButton(
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.blue),
                  onPressed: _togglePause,
                ),
              ],
            ),
          ),
        ),

        // 2. منطقة اللعبة (محمية في المنتصف)
        Expanded(
          child: Stack(
            children: [
              GameWidget(
                game: _game,
                loadingBuilder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              ),
              if (_isPaused) _buildPauseOverlay(),
              // القطعة التالية في ركن الشاشة
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8)),
                  child: SizedBox(
                      width: 40,
                      height: 40,
                      child: NextPieceDisplay(nextPiece: _game.nextPiece)),
                ),
              ),
            ],
          ),
        ),

        // 3. لوحة التحكم (الدراع) - أسفل الشاشة بعيد عن منطقة اللعب
        Container(
          height: 220,
          padding: const EdgeInsets.only(bottom: 20, top: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF1D1E33),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // أزرار الحركة والتدوير
              _buildCircleControl(Icons.arrow_back, () => _game.moveLeft(),
                  Colors.grey[800]!, "Left"),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCircleControl(Icons.arrow_upward,
                      () => _game.rotate(), Colors.blue, "Rotate"),
                  const SizedBox(height: 15),
                  _buildCircleControl(Icons.keyboard_double_arrow_down,
                      () => _game.hardDrop(), Colors.redAccent, "DROP",
                      size: 65),
                ],
              ),
              _buildCircleControl(Icons.arrow_forward, () => _game.moveRight(),
                  Colors.grey[800]!, "Right"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'STATISTICS',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildStatRow('SCORE', '${_game.score}'),
          const SizedBox(height: 10),
          _buildStatRow('LINES', '${_game.linesCleared}'),
          const SizedBox(height: 10),
          _buildStatRow('LEVEL', '${_game.level}'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
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
    );
  }

  Widget _buildNextPieceSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'NEXT PIECE',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            height: 80,
            child: NextPieceDisplay(nextPiece: _game.nextPiece),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'CONTROLS',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
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
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 24),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTROLS:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildInstructionRow('← →', 'Move'),
          _buildInstructionRow('↑', 'Rotate'),
          _buildInstructionRow('↓', 'Soft Drop'),
          _buildInstructionRow('SPACE', 'Hard Drop'),
          _buildInstructionRow('P', 'Pause'),
        ],
      ),
    );
  }

  Widget _buildInstructionRow(String key, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              key,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            action,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pause_circle_filled,
              size: 60,
              color: Colors.yellow,
            ),
            const SizedBox(height: 15),
            const Text(
              'GAME PAUSED',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _togglePause,
              icon: const Icon(Icons.play_arrow),
              label: const Text('RESUME'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildCircleControl(IconData icon, VoidCallback onTap, Color color, String label, {double size = 55}) {
  return Column(
    children: [
      GestureDetector(
        onTapDown: (_) => onTap(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color, 
            shape: BoxShape.circle, 
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)]
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.6),
        ),
      ),
      if (label.isNotEmpty) Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
    ],
  );
}
}
