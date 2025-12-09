class AngleController {
  AngleController();

  double? angle;
  bool get hasValue => angle != null;
}

class AnalogAngleController extends AngleController {
  AnalogAngleController();

  double? voltage;
  @override
  bool get hasValue => voltage != null && angle != null;
}

class JointController {
  JointController({required this.analogIndex});

  bool isEnabled = true;
  int analogIndex;

  late final lowest = AnalogAngleController();
  late final highest = AnalogAngleController();
  late final target = AngleController();

  bool get hasValue => lowest.hasValue && highest.hasValue && target.hasValue;

  double angleFromVoltage(double voltage) => _linearInterpolate(
    voltage,
    lowest.voltage,
    highest.voltage,
    lowest.angle,
    highest.angle,
  );

  double voltageFromAngle(double angle) => _linearInterpolate(
    angle,
    lowest.angle,
    highest.angle,
    lowest.voltage,
    highest.voltage,
  );

  double _linearInterpolate(
    double? value,
    double? inMin,
    double? inMax,
    double? outMin,
    double? outMax,
  ) {
    if (value == null ||
        inMin == null ||
        inMax == null ||
        outMin == null ||
        outMax == null ||
        inMax - inMin == 0) {
      return double.nan;
    }
    return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
  }
}

enum Joint { ankle, knee }

class JointsManager {
  JointsManager._();
  static final JointsManager instance = JointsManager._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isInitialized = true;
  }

  Joint joint = Joint.ankle;
  final left = JointController(analogIndex: 0);
  final right = JointController(analogIndex: 1);

  bool get isConfigured {
    if (!_isInitialized) {
      throw Exception(
        'PositionsManager is not initialized. Call initialize() first.',
      );
    }

    return left.hasValue && right.hasValue;
  }
}
