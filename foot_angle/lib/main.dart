import 'package:flutter/material.dart';
import 'package:foot_angle/screens/config_page.dart';
import 'package:foot_angle/screens/feedback_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vise ton pied',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      initialRoute: ConfigPage.routeName,
      routes: {
        FeedbackPage.routeName: (context) =>
            const FeedbackPage(title: 'Vise ton pied'),
        ConfigPage.routeName: (context) =>
            const ConfigPage(title: 'Configuration'),
      },
    );
  }
}
