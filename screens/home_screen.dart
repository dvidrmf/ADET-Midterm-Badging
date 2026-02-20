import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tool_module.dart';
import '../providers/app_state.dart';
import '../modules/study_timer_module.dart';
import '../modules/expense_splitter_module.dart';
import '../modules/grade_calc_module.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<ToolModule> modules = [
    StudyTimerModule(),
    ExpenseSplitterModule(),
    GradeCalcModule(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: theme.headerGradient,
            boxShadow: [
              BoxShadow(
                color: theme.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.accent.withValues(alpha: 0.2),
                    child: Text(
                      state.displayName.isNotEmpty
                          ? state.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: theme.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Welcome, ${state.displayName} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          modules[_currentIndex].title,
                          style: TextStyle(
                            color: theme.accent.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.settings_outlined, color: theme.accent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: modules.map<Widget>((m) => m.buildBody(context)).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: theme.accent,
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: modules
              .map((m) => BottomNavigationBarItem(
                    icon: Icon(m.icon),
                    label: m.title,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
