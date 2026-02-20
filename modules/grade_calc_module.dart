import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tool_module.dart';
import '../providers/app_state.dart';

class GradeCalcModule extends ToolModule {
  @override
  String get title => 'Grade Calc';

  @override
  IconData get icon => Icons.school_outlined;

  @override
  Widget buildBody(BuildContext context) => const _GradeCalcBody();
}

// --------------- Data Model ---------------

class _GradeEntry {
  final TextEditingController subjectCtrl;
  final TextEditingController gradeCtrl;
  final TextEditingController weightCtrl;

  _GradeEntry({String subject = '', String grade = '', String weight = ''})
    : subjectCtrl = TextEditingController(text: subject),
      gradeCtrl = TextEditingController(text: grade),
      weightCtrl = TextEditingController(text: weight);

  void dispose() {
    subjectCtrl.dispose();
    gradeCtrl.dispose();
    weightCtrl.dispose();
  }
}

// --------------- Stateful Widget ---------------

class _GradeCalcBody extends StatefulWidget {
  const _GradeCalcBody();

  @override
  State<_GradeCalcBody> createState() => _GradeCalcBodyState();
}

class _GradeCalcBodyState extends State<_GradeCalcBody>
    with TickerProviderStateMixin {
  final List<_GradeEntry> _entries = [
    _GradeEntry(subject: 'Mathematics', grade: '', weight: ''),
    _GradeEntry(subject: 'English', grade: '', weight: ''),
    _GradeEntry(subject: 'Science', grade: '', weight: ''),
  ];

  double? _finalGrade;
  bool _showConfetti = false;
  final List<_ConfettiParticle> _particles = [];
  Timer? _confettiTimer;

  // Animation controllers for confetti
  late List<AnimationController> _confettiControllers;

  @override
  void initState() {
    super.initState();
    _confettiControllers = [];
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.dispose();
    }
    for (final c in _confettiControllers) {
      c.dispose();
    }
    _confettiTimer?.cancel();
    super.dispose();
  }

  void _addEntry() {
    setState(() => _entries.add(_GradeEntry()));
  }

  void _removeEntry(int i) {
    if (_entries.length <= 1) return;
    _entries[i].dispose();
    setState(() {
      _entries.removeAt(i);
      _finalGrade = null;
    });
  }

  void _calculate() {
    double totalWeightedGrade = 0;
    double totalWeight = 0;
    bool hasError = false;

    for (final e in _entries) {
      final grade = double.tryParse(e.gradeCtrl.text);
      final weight = double.tryParse(e.weightCtrl.text);

      if (grade == null || weight == null) {
        hasError = true;
        break;
      }
      totalWeightedGrade += grade * weight;
      totalWeight += weight;
    }

    if (hasError || totalWeight == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '⚠️ Fill in all grades and weights!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final result = totalWeightedGrade / totalWeight;
    setState(() {
      _finalGrade = result;
    });

    _triggerConfetti();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _showCongratsDialog(result);
    });
  }

  void _triggerConfetti() {
    final rng = Random();
    final emojis = ['🎉', '⭐', '🌟', '🎊', '🏆', '✨', '🎈', '💫'];

    for (final c in _confettiControllers) {
      c.dispose();
    }
    _confettiControllers.clear();
    _particles.clear();

    for (int i = 0; i < 20; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1500 + rng.nextInt(1000)),
      );
      _confettiControllers.add(ctrl);

      _particles.add(
        _ConfettiParticle(
          emoji: emojis[rng.nextInt(emojis.length)],
          x: rng.nextDouble(),
          delay: rng.nextDouble() * 0.5,
          controller: ctrl,
        ),
      );

      Future.delayed(
        Duration(milliseconds: (rng.nextDouble() * 400).toInt()),
        () {
          if (mounted) ctrl.forward();
        },
      );
    }

    setState(() => _showConfetti = true);

    _confettiTimer?.cancel();
    _confettiTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showConfetti = false);
    });
  }

  void _showCongratsDialog(double grade) {
    final theme = context.read<AppState>().theme;
    final gradeLabel = grade >= 90
        ? '🏆 Outstanding!'
        : grade >= 80
        ? '⭐ Great Job!'
        : grade >= 75
        ? '👍 You Passed!'
        : '📚 Keep Working!';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.accent, width: 2),
        ),
        title: Text(
          'Congrats! You did great! 🎓',
          style: TextStyle(
            color: theme.accent,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '✨ ✨ ✨',
              style: const TextStyle(fontSize: 32),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Weighted Average:',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '${grade.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                gradeLabel,
                style: TextStyle(
                  color: theme.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Awesome! 🎉'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;

    return Stack(
      children: [
        // ---- Main Content ----
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.accent, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Enter each subject\'s grade (0–100) and its weight percentage.',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Column Headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Expanded(
                    flex: 3,
                    child: Text(
                      'Subject',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'Grade',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'Weight %',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Grade Entries
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _entries.length,
              itemBuilder: (ctx, i) => _GradeRow(
                entry: _entries[i],
                accentColor: theme.accent,
                primaryColor: theme.primary,
                onDelete: _entries.length > 1 ? () => _removeEntry(i) : null,
              ),
            ),

            const SizedBox(height: 12),

            // Add Row Button
            TextButton.icon(
              onPressed: _addEntry,
              icon: Icon(Icons.add_circle_outline, color: theme.accent),
              label: Text('Add Subject', style: TextStyle(color: theme.accent)),
            ),

            const SizedBox(height: 20),

            // Calculate Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: const Text(
                  'CALCULATE GRADE',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Result Display
            if (_finalGrade != null) ...[
              const SizedBox(height: 24),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primary.withOpacity(0.4),
                      theme.secondary.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.accent, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      'Final Grade',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _finalGrade!.toStringAsFixed(2),
                      style: TextStyle(
                        color: theme.accent,
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      _getGradeRemark(_finalGrade!),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),

        // ---- Confetti Overlay ----
        if (_showConfetti)
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: _particles
                    .map((p) => _ConfettiWidget(particle: p))
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }

  String _getGradeRemark(double g) {
    if (g >= 95) return '🏆 Summa Cum Laude!';
    if (g >= 90) return '⭐ Excellent!';
    if (g >= 85) return '😊 Very Good!';
    if (g >= 80) return '👍 Good!';
    if (g >= 75) return '✅ Passed!';
    return '📚 Keep Studying!';
  }
}

// --------------- Grade Row Widget ---------------

class _GradeRow extends StatelessWidget {
  final _GradeEntry entry;
  final Color accentColor;
  final Color primaryColor;
  final VoidCallback? onDelete;

  const _GradeRow({
    required this.entry,
    required this.accentColor,
    required this.primaryColor,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: entry.subjectCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Subject',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: entry.gradeCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: '0–100',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: entry.weightCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: '%',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: onDelete != null
                ? IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: onDelete,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}

// --------------- Confetti Data Model + Widget ---------------

class _ConfettiParticle {
  final String emoji;
  final double x; // 0..1 horizontal position
  final double delay;
  final AnimationController controller;

  _ConfettiParticle({
    required this.emoji,
    required this.x,
    required this.delay,
    required this.controller,
  });
}

class _ConfettiWidget extends StatelessWidget {
  final _ConfettiParticle particle;

  const _ConfettiWidget({required this.particle});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: particle.controller,
      builder: (ctx, _) {
        final t = particle.controller.value;
        final yPos = size.height * (0.1 + t * 0.85);
        final xPos = size.width * particle.x + sin(t * 3.14 * 3) * 30;
        final opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
        final scale = 0.8 + sin(t * 3.14) * 0.4;

        return Positioned(
          left: xPos,
          top: yPos,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Text(particle.emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
        );
      },
    );
  }
}
