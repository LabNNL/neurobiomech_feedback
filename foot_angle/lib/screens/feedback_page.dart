import 'package:flutter/material.dart';
import 'package:foot_angle/managers/positions_manager.dart';
import 'package:foot_angle/screens/config_page.dart';
import 'package:frontend_fundamentals/managers/neurobio_client.dart';

class FeedbackPage extends StatefulWidget {
  static const String routeName = '/feedback';

  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _neurobioClient = NeurobioClient.instance;
  final _positionManager = PositionsManager.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Vise ton pied'),
      ),
      body: Center(
        child: Column(
          children: [
            Text(
              'État du serveur neurobiomech: '
              '${_neurobioClient.isConnected ? "Connecté" : "Déconnecté"}',
            ),
            SizedBox(height: 20),
            Text(
              'Configuration des positions du pied gauche : '
              '${_positionManager.lowestLeftFoot.angle} - ${_positionManager.highestLeftFoot.angle} '
              '(${_positionManager.lowestLeftFoot.voltage} - ${_positionManager.highestLeftFoot.voltage})',
            ),
            SizedBox(height: 20),
            Text(
              'Configuration des positions du pied droit : '
              '${_positionManager.lowestRightFoot.angle} - ${_positionManager.highestRightFoot.angle} '
              '(${_positionManager.lowestRightFoot.voltage} - ${_positionManager.highestRightFoot.voltage})',
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pushReplacementNamed(ConfigPage.routeName);
              },
              child: Text('Configurer les positions'),
            ),
          ],
        ),
      ),
    );
  }
}
