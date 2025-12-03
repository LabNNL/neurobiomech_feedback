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

  double _leftData = 0.0;
  double _rightData = 0.0;

  @override
  void initState() {
    super.initState();

    _neurobioClient.onNewLiveAnalogsData.addListener(_onNewData);
  }

  @override
  void dispose() {
    _neurobioClient.onNewLiveAnalogsData.removeListener(_onNewData);
    super.dispose();
  }

  void _onNewData() {
    final data = _neurobioClient.liveAnalogsData.copy();
    data.dropBefore(DateTime.now().subtract(const Duration(milliseconds: 400)));
    if (data.isEmpty) {
      _leftData = 0.0;
      _rightData = 0.0;
      return;
    }

    final rawData = data.delsysEmg.getData(raw: true);
    final avgLeft =
        rawData[_positionManager.leftFootEmgIndex].reduce(
          (value, element) => value + element,
        ) /
        rawData[_positionManager.leftFootEmgIndex].length;
    final avgRight =
        rawData[_positionManager.rightFootEmgIndex].reduce(
          (value, element) => value + element,
        ) /
        rawData[_positionManager.rightFootEmgIndex].length;
    setState(() {
      _leftData = avgLeft;
      _rightData = avgRight;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Vise ton pied'),
      ),
      body: Column(
        children: [
          _DebugInformation(leftData: _leftData, rightData: _rightData),
        ],
      ),
    );
  }
}

class _DebugInformation extends StatelessWidget {
  const _DebugInformation({required this.leftData, required this.rightData});

  final double leftData;
  final double rightData;

  @override
  Widget build(BuildContext context) {
    final neurobioClient = NeurobioClient.instance;
    final positionManager = PositionsManager.instance;

    return Center(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('État du serveur neurobiomech: '),
              Text(
                neurobioClient.isConnected ? "Connecté" : "Déconnecté",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            'Configuration des positions du pied gauche : '
            '[${positionManager.lowestLeftFoot.angle}, ${positionManager.targetLeftFoot.angle}, ${positionManager.highestLeftFoot.angle}] '
            '(${positionManager.lowestLeftFoot.voltage?.toStringAsFixed(3)}, ${positionManager.leftVoltageFromAngle(positionManager.targetLeftFoot.angle ?? 0).toStringAsFixed(3)}, ${positionManager.highestLeftFoot.voltage?.toStringAsFixed(3)})',
          ),
          Text(
            'Configuration des positions du pied droit : '
            '[${positionManager.lowestRightFoot.angle}, ${positionManager.targetRightFoot.angle}, ${positionManager.highestRightFoot.angle}] '
            '(${positionManager.lowestRightFoot.voltage?.toStringAsFixed(3)},  ${positionManager.rightVoltageFromAngle(positionManager.targetRightFoot.angle ?? 0).toStringAsFixed(3)}, ${positionManager.highestRightFoot.voltage?.toStringAsFixed(3)})',
          ),
          Text(
            'Position actuelle: ${positionManager.leftAngleFromVoltage(leftData).toStringAsFixed(3)} (${leftData.toStringAsFixed(3)}), '
            '${positionManager.rightAngleFromVoltage(rightData).toStringAsFixed(3)} (${rightData.toStringAsFixed(3)})',
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed(ConfigPage.routeName);
            },
            child: Text('Configurer les positions'),
          ),
        ],
      ),
    );
  }
}
