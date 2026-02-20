import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tool_module.dart';
import '../providers/app_state.dart';

class StudyTimerModule extends ToolModule {
  @override
  String get title => 'Study Timer';

  @override
  IconData get icon => Icons.timer_outlined;

  @override
  Widget buildBody(BuildContext context) => const _StudyTimerBody();
}

class _StudyTimerBody extends StatefulWidget {
  const _StudyTimerBody();

  @override
  State<_StudyTimerBody> createState() => _StudyTimerBodyState();
}

class _StudyTimerBodyState extends State<_StudyTimerBody>
    with SingleTickerProviderStateMixin {
  double _sliderMinutes = 25.0;
  int _secondsRemaining = 0;
  bool _isRunning = false;
  bool _isFinished = false;
  Timer? _timer;

  late AnimationController _rotationController;
  late Animation<double> _rotationAnim;

  final List<String> _completedSessions = [];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _rotationAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = (_sliderMinutes * 60).toInt();
    _isRunning = true;
    _isFinished = false;
    _rotationController.reset();
    setState(() {});

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining <= 0) {
        t.cancel();
        _onTimerFinished();
      } else {
        setState(() => _secondsRemaining--);
        final progress =
            1 -
            (_secondsRemaining /
                (_sliderMinutes * 60).clamp(1, double.infinity));
        _rotationController.animateTo(
          progress,
          duration: const Duration(milliseconds: 500),
        );
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isFinished = false;
    });
  }

  void _onTimerFinished() {
    _rotationController.forward();
    setState(() {
      _isRunning = false;
      _isFinished = true;
    });
    final now = DateTime.now();
    final label = '${_sliderMinutes.toInt()} min session — ${_formatTime(now)}';
    setState(() => _completedSessions.insert(0, label));
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String get _countdownText {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _TimerVisual(
          rotationAnim: _rotationAnim,
          isFinished: _isFinished,
          isRunning: _isRunning,
          accentColor: theme.accent,
          primaryColor: theme.primary,
        ),

        const SizedBox(height: 28),

        if (_isRunning || _isFinished)
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: _isFinished
                  ? theme.accent.withOpacity(0.15)
                  : theme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFinished ? theme.accent : theme.primary,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                _isFinished ? 'Done!' : _countdownText,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: _isFinished ? theme.accent : Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),

        const SizedBox(height: 24),

        if (!_isRunning) ...[
          Text(
            'Duration: ${_sliderMinutes.toInt()} minutes',
            style: TextStyle(
              color: theme.accent,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _sliderMinutes,
            min: 5,
            max: 120,
            divisions: 23,
            label: '${_sliderMinutes.toInt()} min',
            onChanged: (v) => setState(() => _sliderMinutes = v),
          ),
          const SizedBox(height: 16),
        ],

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _startTimer,
                icon: const Icon(Icons.play_arrow),
                label: const Text('START'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isRunning ? _stopTimer : null,
                icon: const Icon(Icons.stop),
                label: const Text('STOP'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        Text(
          '📋 Completed Sessions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),

        if (_completedSessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No sessions yet. Start your first one!',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _completedSessions.length,
            itemBuilder: (ctx, i) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Text(
                    '${i + 1}.',
                    style: TextStyle(
                      color: theme.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _completedSessions[i],
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TimerVisual extends StatelessWidget {
  final Animation<double> rotationAnim;
  final bool isFinished;
  final bool isRunning;
  final Color accentColor;
  final Color primaryColor;

  const _TimerVisual({
    required this.rotationAnim,
    required this.isFinished,
    required this.isRunning,
    required this.accentColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFinished
              ? accentColor.withOpacity(0.2)
              : primaryColor.withOpacity(0.15),
          border: Border.all(
            color: isFinished ? accentColor : primaryColor,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: (isFinished ? accentColor : primaryColor).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: rotationAnim,
          builder: (ctx, child) {
            return Transform.rotate(
              angle: rotationAnim.value * 3.14159,
              child: Center(
                child: Text(
                  isFinished
                      ? '🌞'
                      : isRunning
                      ? '🌙'
                      : '😴',
                  style: const TextStyle(fontSize: 64),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
