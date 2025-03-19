import 'package:flutter/material.dart';
import 'pages/ai_assistant_entry.dart';

class AIAssistant extends StatelessWidget {
  const AIAssistant({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4F7DC9),
          secondary: Color(0xFF82D2B4),
          surface: Color(0xFF1C1C28),
          background: Color(0xFF121212),
        ),
      ),
      home: const Scaffold(
        backgroundColor: Colors.transparent,
        body: AIAssistantEntry(),
      ),
    );
  }
}
