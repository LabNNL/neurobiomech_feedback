class PositionController {
  PositionController({required this.emgIndex});

  int emgIndex;

  double? angle;
  bool get hasValue => angle != null;
}

class AnalogPositionController extends PositionController {
  AnalogPositionController({required super.emgIndex});

  double? voltage;
  @override
  bool get hasValue => voltage != null && angle != null;
}

class PositionsManager {
  // Create the singleton instance
  PositionsManager._();
  static final PositionsManager instance = PositionsManager._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    // Placeholder for any future initialization code
    _isInitialized = true;
  }

  int get leftFootEmgIndex => 0;
  late final lowestLeftFoot = AnalogPositionController(
    emgIndex: leftFootEmgIndex,
  );
  late final highestLeftFoot = AnalogPositionController(
    emgIndex: leftFootEmgIndex,
  );
  late final targetLeftFoot = PositionController(emgIndex: leftFootEmgIndex);
  double leftAngleFromVoltage(double voltage) =>
      _angleFromVoltage(voltage, lowestLeftFoot, highestLeftFoot);
  double leftVoltageFromAngle(double angle) =>
      _voltageFromAngle(angle, lowestLeftFoot, highestLeftFoot);

  int get rightFootEmgIndex => 1;
  late final lowestRightFoot = AnalogPositionController(
    emgIndex: rightFootEmgIndex,
  );
  late final highestRightFoot = AnalogPositionController(
    emgIndex: rightFootEmgIndex,
  );
  late final targetRightFoot = PositionController(emgIndex: rightFootEmgIndex);
  double rightAngleFromVoltage(double voltage) =>
      _angleFromVoltage(voltage, lowestRightFoot, highestRightFoot);
  double rightVoltageFromAngle(double angle) =>
      _voltageFromAngle(angle, lowestRightFoot, highestRightFoot);

  bool get isConfigured {
    if (!_isInitialized) {
      throw Exception(
        'PositionsManager is not initialized. Call initialize() first.',
      );
    }

    return lowestLeftFoot.hasValue &&
        highestLeftFoot.hasValue &&
        targetLeftFoot.hasValue &&
        lowestRightFoot.hasValue &&
        highestRightFoot.hasValue &&
        targetRightFoot.hasValue;
  }
}

double _voltageFromAngle(
  double angle,
  AnalogPositionController lowest,
  AnalogPositionController highest,
) {
  if (lowest.voltage == null ||
      highest.voltage == null ||
      lowest.angle == null ||
      highest.angle == null) {
    throw Exception('Positions are not fully configured.');
  }

  // Example linear mapping; adjust as needed
  final minVoltage = lowest.voltage!;
  final maxVoltage = highest.voltage!;
  final minAngle = lowest.angle!;
  final maxAngle = highest.angle!;

  return (angle - minAngle) *
          (maxVoltage - minVoltage) /
          (maxAngle - minAngle) +
      minVoltage;
}

double _angleFromVoltage(
  double voltage,
  AnalogPositionController lowest,
  AnalogPositionController highest,
) {
  if (lowest.voltage == null ||
      highest.voltage == null ||
      lowest.angle == null ||
      highest.angle == null) {
    return double.nan;
  }

  // Example linear mapping; adjust as needed
  final minVoltage = lowest.voltage!;
  final maxVoltage = highest.voltage!;
  final minAngle = lowest.angle!;
  final maxAngle = highest.angle!;
  if (maxVoltage - minVoltage == 0) return double.nan;

  return (voltage - minVoltage) *
          (maxAngle - minAngle) /
          (maxVoltage - minVoltage) +
      minAngle;
}
