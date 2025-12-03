import 'package:flutter/material.dart';
import 'package:foot_angle/managers/positions_manager.dart';
import 'package:foot_angle/screens/config_page.dart';
import 'package:foot_angle/screens/feedback_page.dart';
import 'package:frontend_fundamentals/managers/neurobio_client.dart';
import 'package:frontend_fundamentals/managers/predictions_manager.dart';
import 'package:logging/logging.dart';

Future<void> main() async {
  // Configure logging
  Logger.root.onRecord.listen((record) {
    if (record.level >= Level.INFO) {
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    }
  });

  const bool.fromEnvironment('USE_BACKEND_MOCK')
      ? await NeurobioClientMock.instance.initialize()
      : await NeurobioClient.instance.initialize();

  await PositionsManager.instance.initialize();
  await PredictionsManager.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vise ton pied',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      initialRoute: ConfigPage.routeName,
      routes: {
        ConfigPage.routeName: (context) => const ConfigPage(),
        FeedbackPage.routeName: (context) => const FeedbackPage(),
      },
    );
  }
}
