import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foot_angle/screens/feedback_page.dart';
import 'package:frontend_common/managers/neurobio_client.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ConfigPage');

class ConfigPage extends StatefulWidget {
  static const String routeName = '/config';

  const ConfigPage({super.key, required this.title});
  final String title;

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  Completer<void>? _isDoingSomething;
  bool get _isBusy =>
      _isDoingSomething != null && !_isDoingSomething!.isCompleted;

  final neurobioClient = NeurobioClient.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _isBusy
                  ? null
                  : () async => await _doSomething(
                      (neurobioClient.isConnected
                          ? _disconnectServer
                          : _connectServer),
                    ),
              child: Text(
                neurobioClient.isConnected ? 'Déconnexion' : 'Connexion',
              ),
            ),
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

  Future<void> _connectServer() async {
    final isSuccess = await neurobioClient.connect(nbOfRetries: 5);
    if (!isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La connexion au serveur neurobiomech a échoué'),
          ),
        );
      }
    }
  }

  Future<void> _disconnectServer() async {
    await neurobioClient.disconnect();
  }

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
}
