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

class _GradeEntry {
  final TextEditingController subjectCtrl;
  final TextEditingController gradeCtrl;
  final TextEditingController unitsCtrl;

  _GradeEntry({String subject = '', String grade = '', String units = ''})
      : subjectCtrl = TextEditingController(text: subject),
        gradeCtrl = TextEditingController(text: grade),
        unitsCtrl = TextEditingController(text: units);

  void dispose() {
    subjectCtrl.dispose();
    gradeCtrl.dispose();
    unitsCtrl.dispose();
  }
}

class _GradeCalcBody extends StatefulWidget {
  const _GradeCalcBody();

  @override
  State<_GradeCalcBody> createState() => _GradeCalcBodyState();
}

class _GradeCalcBodyState extends State<_GradeCalcBody>
    with TickerProviderStateMixin {
  final List<_GradeEntry> _entries = [
    _GradeEntry(subject: 'Math 101', units: '3'),
    _GradeEntry(subject: 'English 101', units: '3'),
    _GradeEntry(subject: 'Physics 101', units: '3'),
    _GradeEntry(subject: 'PE 1', units: '2'),
  ];

  double? _gpa;
  bool _showConfetti = false;
  final List<_ConfettiParticle> _particles = [];
  Timer? _confettiTimer;
  late List<AnimationController> _confettiControllers;

  double _percentToGradePoint(double percent) {
    if (percent >= 99) return 1.00;
    if (percent >= 95) return 1.25;
    if (percent >= 90) return 1.50;
    if (percent >= 85) return 1.75;
    if (percent >= 80) return 2.00;
    if (percent >= 75) return 2.25;
    if (percent >= 70) return 2.50;
    if (percent >= 65) return 2.75;
    if (percent >= 60) return 3.00;
    return 5.00;
  }

  String _gpToDescription(double gp) {
    if (gp <= 1.00) return 'Excellent';
    if (gp <= 1.50) return 'Very Good';
    if (gp <= 2.00) return 'Good';
    if (gp <= 2.50) return 'Satisfactory';
    if (gp <= 3.00) return 'Passing';
    return 'Failing';
  }

  String _gpToEquivalence(double gp) {
    if (gp <= 1.00) return '99–100%';
    if (gp <= 1.25) return '95–98%';
    if (gp <= 1.50) return '90–94%';
    if (gp <= 1.75) return '85–89%';
    if (gp <= 2.00) return '80–84%';
    if (gp <= 2.25) return '75–79%';
    if (gp <= 2.50) return '70–74%';
    if (gp <= 2.75) return '65–69%';
    if (gp <= 3.00) return '60–64%';
    return '<60%';
  }

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
      _gpa = null;
    });
  }

  void _calculate() {
    double totalWeightedGP = 0;
    double totalUnits = 0;
    bool hasError = false;

    for (final e in _entries) {
      final percent = double.tryParse(e.gradeCtrl.text);
      final units = double.tryParse(e.unitsCtrl.text);
      if (percent == null || units == null) {
        hasError = true;
        break;
      }
      totalWeightedGP += _percentToGradePoint(percent) * units;
      totalUnits += units;
    }

    if (hasError || totalUnits == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ Fill in all grades and units!',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final result = totalWeightedGP / totalUnits;
    setState(() => _gpa = result);
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
      _particles.add(_ConfettiParticle(
        emoji: emojis[rng.nextInt(emojis.length)],
        x: rng.nextDouble(),
        controller: ctrl,
      ));
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

  void _showCongratsDialog(double gpa) {
    final theme = context.read<AppState>().theme;

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
            const Text('✨ ✨ ✨',
                style: TextStyle(fontSize: 32),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text('Your GWA',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 8),
            Text(
              gpa.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _gpToEquivalence(gpa),
              style: TextStyle(color: theme.accent, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _gpToDescription(gpa),
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

  Widget _scaleRow(String gp, String equiv, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(gp,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: 70,
            child: Text(equiv,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 11)),
          ),
          Text(desc,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 11)),
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
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: theme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.accent, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Enter grade (%) and units per subject. GWA is computed using the college grade point system.',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📊 Grading Scale',
                      style: TextStyle(
                          color: theme.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 10),
                  _scaleRow('1.00', '99–100%', 'Excellent', theme.accent),
                  _scaleRow('1.25', '95–98%', 'Very Good', Colors.white70),
                  _scaleRow('1.50', '90–94%', 'Very Good', Colors.white70),
                  _scaleRow('1.75', '85–89%', 'Good', Colors.white70),
                  _scaleRow('2.00', '80–84%', 'Good', Colors.white70),
                  _scaleRow('2.25', '75–79%', 'Satisfactory', Colors.white70),
                  _scaleRow('2.50', '70–74%', 'Satisfactory', Colors.white70),
                  _scaleRow('2.75', '65–69%', 'Passing', Colors.white70),
                  _scaleRow('3.00', '60–64%', 'Passing', Colors.white70),
                  _scaleRow('5.00', '<60%', 'Failing', Colors.redAccent),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('Subject',
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text('Grade %',
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text('Units',
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text('GP',
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(width: 36),
                ],
              ),
            ),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _entries.length,
              itemBuilder: (ctx, i) {
                final percent =
                    double.tryParse(_entries[i].gradeCtrl.text);
                final gpDisplay = percent != null
                    ? _percentToGradePoint(percent).toStringAsFixed(2)
                    : '—';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _entries[i].subjectCtrl,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Subject',
                            hintStyle: TextStyle(
                                color: Colors.white24, fontSize: 13),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _entries[i].gradeCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: '0–100',
                            hintStyle: TextStyle(
                                color: Colors.white24, fontSize: 13),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _entries[i].unitsCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Units',
                            hintStyle: TextStyle(
                                color: Colors.white24, fontSize: 13),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 14),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    theme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            gpDisplay,
                            style: TextStyle(
                              color: theme.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: _entries.length > 1
                            ? IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.redAccent,
                                    size: 20),
                                onPressed: () => _removeEntry(i),
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            TextButton.icon(
              onPressed: _addEntry,
              icon: Icon(Icons.add_circle_outline, color: theme.accent),
              label: Text('Add Subject',
                  style: TextStyle(color: theme.accent)),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: const Text(
                  'COMPUTE GWA',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (_gpa != null) ...[
              const SizedBox(height: 24),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primary.withValues(alpha: 0.4),
                      theme.secondary.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.accent, width: 2),
                ),
                child: Column(
                  children: [
                    const Text('General Weighted Average',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      _gpa!.toStringAsFixed(2),
                      style: TextStyle(
                        color: theme.accent,
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _gpToEquivalence(_gpa!),
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _gpToDescription(_gpa!),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),

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
}

class _ConfettiParticle {
  final String emoji;
  final double x;
  final AnimationController controller;

  _ConfettiParticle({
    required this.emoji,
    required this.x,
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
              child: Text(particle.emoji,
                  style: const TextStyle(fontSize: 24)),
            ),
          ),
        );
      },
    );
  }
}
