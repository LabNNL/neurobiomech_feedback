import 'package:flutter/material.dart';
import 'package:foot_angle/screens/feedback_page.dart';

class ConfigPage extends StatelessWidget {
  static const String routeName = '/config';

  const ConfigPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mettre la configuration ici'),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pushReplacementNamed(FeedbackPage.routeName);
              },
              child: const Text('Aller à la page de feedback'),
            ),
          ],
        ),
      ),
    );
  }
}
