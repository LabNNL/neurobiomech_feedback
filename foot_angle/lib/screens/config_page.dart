import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foot_angle/managers/joints_manager.dart';
import 'package:foot_angle/screens/feedback_page.dart';
import 'package:frontend_fundamentals/managers/neurobio_client.dart';
import 'package:frontend_fundamentals/models/server_command.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ConfigPage');

final _angleInputFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'(^-?\d*\.?\d{0,2})'),
);

class ConfigPage extends StatefulWidget {
  static const String routeName = '/config';

  const ConfigPage({super.key, this.isDrawer = false});

  final bool isDrawer;

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _neurobioClient = NeurobioClient.instance;
  final _jointsManager = JointsManager.instance;

  final _formKey = GlobalKey<FormState>();

  bool get _isFullyConfigured =>
      _neurobioClient.isConnected && _jointsManager.isConfigured;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Configuration'),
        actions: [
          if (widget.isDrawer)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: Form(
            key: _formKey,
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
                DropdownButton(
                  items: [
                    ...Joint.values.map(
                      (joint) => DropdownMenuItem(
                        value: joint,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(joint.name),
                        ),
                      ),
                    ),
                  ],
                  value: _jointsManager.joint,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _jointsManager.joint = value);
                    }
                  },
                ),
                Text(_jointsManager.joint.direction),
                SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildJointSetters(
                      controller: _jointsManager.left,
                      titleSuffix: _jointsManager.joint.titleSuffix(
                        side: Side.left,
                      ),
                    ),
                    SizedBox(width: 20),
                    _buildJointSetters(
                      controller: _jointsManager.right,
                      titleSuffix: _jointsManager.joint.titleSuffix(
                        side: Side.right,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),
                if (!widget.isDrawer)
                  ElevatedButton(
                    onPressed:
                        _neurobioClient.isConnected &&
                            !_isBusy &&
                            _isFullyConfigured
                        ? () {
                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(FeedbackPage.routeName);
                            }
                          }
                        : null,
                    child: Text('Aller à la page de feedback'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJointSetters({
    required JointController controller,
    required String titleSuffix,
  }) {
    return Column(
      children: [
        _buildSetEnabled(
          controller: controller,
          title: 'Utilisation $titleSuffix',
        ),
        _buildSetChannelIndex(
          controller: controller,
          titleSuffix: 'Canal $titleSuffix',
        ),
        SizedBox(height: 10),
        _buildSetAnalog(
          channelIndex: controller.analogIndex,
          controller: controller.lowest,
          enabled: controller.enabled,
          title: 'Angle minimal $titleSuffix',
        ),
        SizedBox(height: 10),
        _buildSetAnalog(
          channelIndex: controller.analogIndex,
          controller: controller.highest,
          enabled: controller.enabled,
          title: 'Angle maximal $titleSuffix',
        ),
        SizedBox(height: 10),
        _buildSetTarget(
          channelIndex: controller.analogIndex,
          controller: controller.target,
          enabled: controller.enabled,
          title: 'Angle cible $titleSuffix',
        ),
      ],
    );
  }

  Widget _buildSetEnabled({
    required JointController controller,
    required String title,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() => controller.enabled = !controller.enabled);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: controller.enabled,
              onChanged: (value) {
                setState(() => controller.enabled = value ?? false);
              },
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _buildSetChannelIndex({
    required JointController controller,
    required String titleSuffix,
  }) {
    int? channelIndex(value) {
      final index = int.tryParse(value ?? '') ?? -1;
      return index < 1 || index > 16 ? null : index - 1;
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _formKey.currentState?.validate(),
    );

    return SizedBox(
      width: 100,
      child: TextFormField(
        decoration: InputDecoration(labelText: 'Canal'),
        enabled: controller.enabled,
        initialValue:
            (controller.analogIndex == null ? '' : controller.analogIndex! + 1)
                .toString(),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) => channelIndex(value) == null ? 'De 1 à 16' : null,
        onChanged: (value) =>
            setState(() => controller.analogIndex = channelIndex(value)),
      ),
    );
  }

  Widget _buildSetAnalog({
    required int? channelIndex,
    required bool enabled,
    required AnalogAngleController controller,
    required String title,
  }) {
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
                color: !_neurobioClient.isConnected || !enabled
                    ? Colors.grey
                    : (controller.voltage == null)
                    ? Colors.red
                    : Colors.green,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton(
                onPressed: _neurobioClient.isConnected && !_isBusy && enabled
                    ? () async => await _doSomething(
                        () => _setVoltage(
                          channelIndex: channelIndex,
                          controller: controller,
                        ),
                      )
                    : null,
                child: Text(
                  controller.voltage == null ? 'Mesurer' : 'Re-mesurer',
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Angle',
                  suffixText: '°',
                ),
                enabled: enabled,
                initialValue: controller.angle?.toString() ?? '',
                inputFormatters: [_angleInputFormatter],
                onChanged: (value) =>
                    setState(() => controller.angle = double.tryParse(value)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetTarget({
    required int? channelIndex,
    required TargetAngleController controller,
    required bool enabled,
    required String title,
  }) {
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
                color: !_neurobioClient.isConnected || !enabled
                    ? Colors.grey
                    : Colors.green,
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Angle',
                      suffixText: '°',
                    ),
                    enabled: enabled,
                    initialValue: controller.angle?.toString() ?? '',
                    inputFormatters: [_angleInputFormatter],
                    onChanged: (value) => setState(
                      () => controller.angle = double.tryParse(value),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Column(
                  children: [
                    SizedBox(
                      width: 70,
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Succès',
                          prefix: Text('± '),
                          suffixText: '°',
                        ),
                        enabled: enabled,
                        initialValue: controller.tolerance?.toString() ?? '',
                        inputFormatters: [_angleInputFormatter],
                        onChanged: (value) => setState(
                          () => controller.tolerance = double.tryParse(value),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Acceptable',
                          prefix: Text('± '),
                          suffixText: '°',
                        ),
                        enabled: enabled,
                        initialValue:
                            controller.almostTolerance?.toString() ?? '',
                        inputFormatters: [_angleInputFormatter],
                        onChanged: (value) => setState(
                          () => controller.almostTolerance = double.tryParse(
                            value,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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

  Future<void> _setVoltage({
    required int? channelIndex,
    required AnalogAngleController controller,
  }) async {
    if (!_neurobioClient.isConnected ||
        !_neurobioClient.isConnectedToDelsysEmg) {
      _showErrorSnackBar(
        'Impossible de prendre la mesure : non connecté au serveur neurobiomech',
      );
      return;
    }
    if (channelIndex == null) {
      _showErrorSnackBar(
        'Impossible de prendre la mesure : canal non configuré',
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
