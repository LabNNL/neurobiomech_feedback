import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foot_angle/managers/positions_manager.dart';
import 'package:foot_angle/screens/feedback_page.dart';
import 'package:frontend_fundamentals/managers/neurobio_client.dart';
import 'package:frontend_fundamentals/models/server_command.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ConfigPage');

class ConfigPage extends StatefulWidget {
  static const String routeName = '/config';

  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _neurobioClient = NeurobioClient.instance;
  final _positionManager = PositionsManager.instance;

  bool get _isFullyConfigured =>
      _neurobioClient.isConnected && _positionManager.isConfigured;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Configuration'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20),
            Text('Connexion au serveur neurobiomech'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: !_isBusy
                  ? () async => await _doSomething(
                      (_neurobioClient.isConnected
                          ? _disconnectServer
                          : _connectServer),
                    )
                  : null,
              child: Text(
                _neurobioClient.isConnected ? 'Déconnexion' : 'Connexion',
              ),
            ),
            SizedBox(height: 20),
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSetPosition(
                      controller: _positionManager.lowestLeftFoot,
                      title: 'Position minimale du pied gauche',
                    ),
                    SizedBox(width: 20),
                    _buildSetPosition(
                      controller: _positionManager.lowestRightFoot,
                      title: 'Position minimale du pied droit',
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSetPosition(
                      controller: _positionManager.highestLeftFoot,
                      title: 'Position maximale du pied gauche',
                    ),
                    SizedBox(width: 20),
                    _buildSetPosition(
                      controller: _positionManager.highestRightFoot,
                      title: 'Position maximale du pied droit',
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSetPosition(
                      controller: _positionManager.targetLeftFoot,
                      title: 'Position cible du pied gauche',
                    ),
                    SizedBox(width: 20),
                    _buildSetPosition(
                      controller: _positionManager.targetRightFoot,
                      title: 'Position cible du pied droit',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed:
                  _neurobioClient.isConnected && !_isBusy && _isFullyConfigured
                  ? () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(FeedbackPage.routeName);
                    }
                  : null,
              child: const Text('Aller à la page de feedback'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetPosition({
    required PositionController controller,
    required String title,
  }) {
    bool isAnalog = controller is AnalogPositionController;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: !_neurobioClient.isConnected
                    ? Colors.grey
                    : (isAnalog && controller.voltage == null)
                    ? Colors.red
                    : Colors.green,
              ),
            ),
            if (isAnalog)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton(
                  onPressed: _neurobioClient.isConnected && !_isBusy
                      ? () async =>
                            await _doSomething(() => _setVoltage(controller))
                      : null,
                  child: Text(
                    controller.voltage == null ? 'Mesurer' : 'Re-mesurer',
                  ),
                ),
              ),
            SizedBox(
              width: 120,
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Angle (degrés)',
                  suffixText: '°',
                ),
                initialValue: controller.angle?.toString() ?? '',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  final angle = double.tryParse(value);
                  setState(() => controller.angle = angle);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectServer() async {
    bool isSuccess = await _neurobioClient.connect(nbOfRetries: 5);
    if (!isSuccess) {
      _showErrorSnackBar('La connexion au serveur neurobiomech a échoué');
    }

    isSuccess = await _neurobioClient.send(ServerCommand.getStates);
    if (!isSuccess) {
      await _neurobioClient.disconnect();
      _showErrorSnackBar(
        'La connexion au serveur neurobiomech a échoué (états)',
      );
      return;
    }

    if (!_neurobioClient.isConnectedToDelsysEmg) {
      isSuccess = await _neurobioClient.send(ServerCommand.connectDelsysEmg);
      if (!isSuccess) {
        await _neurobioClient.disconnect();
        _showErrorSnackBar(
          'La connexion au serveur neurobiomech a échoué (EMG)',
        );
      }
    }
  }

  Future<void> _disconnectServer() async {
    await _neurobioClient.disconnect();
  }

  Future<void> _setVoltage(AnalogPositionController controller) async {
    if (!_neurobioClient.isConnected ||
        !_neurobioClient.isConnectedToDelsysEmg) {
      _showErrorSnackBar(
        'Impossible de prendre la mesure : non connecté au serveur neurobiomech',
      );
      return;
    }

    // Wait for collecting at least one second of data
    final startTime = DateTime.now();
    await Future.delayed(Duration(seconds: 1, milliseconds: 200));

    final data = _neurobioClient.liveAnalogsData.copy();
    data.dropBefore(startTime);
    data.dropAfter(startTime.add(Duration(seconds: 1)));
    if (data.isEmpty) {
      _showErrorSnackBar(
        'Impossible de prendre la mesure : aucune donnée reçue du serveur neurobiomech',
      );
      return;
    }
    // Compute the average voltage over the last second
    final channelIndex = controller.emgIndex;
    final avgVoltage =
        data.delsysEmg
            .getData(raw: true)[channelIndex]
            .reduce((a, b) => a + b) /
        data.delsysEmg.length;
    setState(() {
      controller.voltage = avgVoltage;
    });
  }

  Completer<void>? _isDoingSomething;
  bool get _isBusy =>
      _isDoingSomething != null && !_isDoingSomething!.isCompleted;
  Future<void> _doSomething(Future<void> Function() action) async {
    if (_isDoingSomething != null) await _isDoingSomething?.future;

    _isDoingSomething = Completer<void>();
    setState(() {});
    try {
      await action();
    } catch (err, st) {
      _logger.severe('Error during operation', err, st);
    } finally {
      _isDoingSomething?.complete();
      _isDoingSomething = null;
      setState(() {});
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
