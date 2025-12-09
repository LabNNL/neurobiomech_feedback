import 'package:flutter/material.dart';
import 'package:foot_angle/managers/joints_manager.dart';
import 'package:foot_angle/screens/config_page.dart';
import 'package:foot_angle/widgets/joint_painter.dart';
import 'package:frontend_fundamentals/managers/neurobio_client.dart';

class FeedbackPage extends StatefulWidget {
  static const String routeName = '/feedback';

  const FeedbackPage({super.key, this.showDebugInformation = false});

  final bool showDebugInformation;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _neurobioClient = NeurobioClient.instance;
  final _jointsManager = JointsManager.instance;

  double _leftData = 0.0;
  double _rightData = 0.0;

  @override
  void initState() {
    super.initState();

    _neurobioClient.onNewLiveAnalogsData.addListener(_onNewData);

    // On start, open the drawer where configuration can be done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState?.openDrawer();
    });
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
    final leftIndex = _jointsManager.left.analogIndex;
    final rightIndex = _jointsManager.right.analogIndex;
    final avgLeft =
        rawData[leftIndex].reduce((value, element) => value + element) /
        rawData[leftIndex].length;
    final avgRight =
        rawData[rightIndex].reduce((value, element) => value + element) /
        rawData[rightIndex].length;
    setState(() {
      _leftData = avgLeft;
      _rightData = avgRight;
    });
  }

  @override
  Widget build(BuildContext context) {
    final feetSizeFactor = widget.showDebugInformation ? 0.6 : 0.8;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Vise ton pied'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_jointsManager.left.isEnabled)
                    JointPainter(
                      side: FootAndLegSide.left,
                      angle: _jointsManager.left.angleFromVoltage(_leftData),
                      targetAngle: _jointsManager.left.target.angle ?? 0.0,
                      acceptedTolerance: _jointsManager.left.target.tolerance,
                      almostTolerance:
                          _jointsManager.left.target.almostTolerance,
                      acceptedColor: Colors.green,
                      almostColor: Colors.orange,
                      refusedColor: Colors.red,
                      height:
                          MediaQuery.of(context).size.height * feetSizeFactor,
                    ),
                  if (_jointsManager.right.isEnabled)
                    JointPainter(
                      side: FootAndLegSide.right,
                      angle: _jointsManager.right.angleFromVoltage(_rightData),
                      targetAngle: _jointsManager.right.target.angle ?? 0.0,
                      acceptedTolerance: _jointsManager.right.target.tolerance,
                      almostTolerance:
                          _jointsManager.right.target.almostTolerance,
                      acceptedColor: Colors.green,
                      almostColor: Colors.orange,
                      refusedColor: Colors.red,
                      height:
                          MediaQuery.of(context).size.height * feetSizeFactor,
                    ),
                ],
              ),
            ),
            if (widget.showDebugInformation)
              _DebugInformation(leftData: _leftData, rightData: _rightData),
          ],
        ),
      ),
      drawer: Drawer(width: 600, child: ConfigPage(isDrawer: true)),
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
    final jointsManager = JointsManager.instance;

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
            'Configuration des angles de la cheville gauche : '
            '[${jointsManager.left.lowest.angle}, '
            '${jointsManager.left.target.angle}, '
            '${jointsManager.left.highest.angle}] '
            '(${jointsManager.left.lowest.voltage?.toStringAsFixed(3)}, '
            '${jointsManager.left.angleFromVoltage(jointsManager.left.target.angle ?? 0).toStringAsFixed(3)}, '
            '${jointsManager.left.highest.voltage?.toStringAsFixed(3)})',
          ),
          Text(
            'Configuration des angles de la cheville droite : '
            '[${jointsManager.right.lowest.angle}, '
            '${jointsManager.right.target.angle}, '
            '${jointsManager.right.highest.angle}] '
            '(${jointsManager.right.lowest.voltage?.toStringAsFixed(3)}, '
            '${jointsManager.right.angleFromVoltage(jointsManager.right.target.angle ?? 0).toStringAsFixed(3)}, '
            '${jointsManager.right.highest.voltage?.toStringAsFixed(3)})',
          ),
          Text(
            'Angles actuels: ${jointsManager.left.angleFromVoltage(leftData).toStringAsFixed(3)} '
            '(${leftData.toStringAsFixed(3)}), '
            '${jointsManager.right.angleFromVoltage(rightData).toStringAsFixed(3)} (${rightData.toStringAsFixed(3)})',
          ),
        ],
      ),
    );
  }
}
