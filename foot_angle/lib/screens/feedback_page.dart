import 'package:flutter/material.dart';

class FeedbackPage extends StatelessWidget {
  static const String routeName = '/feedback';

  const FeedbackPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(child: const Text('Mettre un pied ici')),
    );
  }
}
