import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/task_home.dart';

class TaskFlowApp extends StatefulWidget {
  const TaskFlowApp({super.key});
  @override
  State<TaskFlowApp> createState() => _TaskFlowAppState();
}

class _TaskFlowAppState extends State<TaskFlowApp> {
  bool dark = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => dark = prefs.getBool('dark') ?? false);
  }

  Future<void> _toggle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark', !dark);
    if (mounted) setState(() => dark = !dark);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TaskFlow',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    darkTheme: ThemeData(
      colorSchemeSeed: Colors.indigo,
      brightness: Brightness.dark,
      useMaterial3: true,
    ),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: TaskHome(onThemeToggle: _toggle, dark: dark),
  );
}
