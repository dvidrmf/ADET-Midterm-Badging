import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.load();

  runApp(
    ChangeNotifierProvider.value(value: appState, child: const UIArtisanApp()),
  );
}

class UIArtisanApp extends StatelessWidget {
  const UIArtisanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return MaterialApp(
      title: 'UI Artisan Toolkit',
      debugShowCheckedModeBanner: false,
      theme: state.materialTheme,
      home: const HomeScreen(),
    );
  }
}
