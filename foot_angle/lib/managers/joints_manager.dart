enum Side { left, right }

enum Joint {
  ankle,
  knee;

  String get name {
    switch (this) {
      case Joint.ankle:
        return 'Cheville';
      case Joint.knee:
        return 'Genou';
    }
  }

  String titleSuffix({required Side side}) {
    switch (this) {
      case Joint.ankle:
        return 'de la cheville ${side == Side.left ? 'gauche' : 'droite'}';
      case Joint.knee:
        return 'du genou ${side == Side.left ? 'gauche' : 'droit'}';
    }
  }

  String get direction {
    switch (this) {
      case Joint.ankle:
        return 'Dorsiflexion (+) / Plantiflexion (-)';
      case Joint.knee:
        return 'Flexion (+) / Extension (-)';
    }
  }

  double get directionModifier {
    switch (this) {
      case Joint.ankle:
        return -1.0;
      case Joint.knee:
        return 1.0;
    }
  }
}

class AngleController {
  AngleController({this.angle});

  double? angle;
  bool get hasValue => angle != null;
}

class AnalogAngleController extends AngleController {
  AnalogAngleController();

  double? voltage;
  @override
  bool get hasValue => voltage != null && angle != null;
}

class TargetAngleController extends AngleController {
  TargetAngleController({
    required super.angle,
    required this.tolerance,
    required this.almostTolerance,
  });

  double? tolerance;
  double? almostTolerance;

  bool isAngleAccepted(double testAngle) {
    if (angle == null || tolerance == null) return false;

    return (testAngle >= angle! - tolerance!) &&
        (testAngle <= angle! + tolerance!);
  }

  bool isAngleAlmostAccepted(double testAngle) {
    if (angle == null || almostTolerance == null) return false;

    return (testAngle >= angle! - almostTolerance!) &&
        (testAngle <= angle! + almostTolerance!);
  }
}

class JointController {
  JointController({required this.side, required this.analogIndex});

  Side side;
  bool isEnabled = true;
  int? analogIndex;

  late final lowest = AnalogAngleController();
  late final highest = AnalogAngleController();
  late final target = TargetAngleController(
    angle: 0,
    tolerance: 15,
    almostTolerance: 30,
  );

  bool get hasValue =>
      analogIndex != null &&
      lowest.hasValue &&
      highest.hasValue &&
      target.hasValue;

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

class JointsManager {
  JointsManager._();
  static final JointsManager instance = JointsManager._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isInitialized = true;
  }

  Joint joint = Joint.ankle;
  final left = JointController(side: Side.left, analogIndex: 0);
  final right = JointController(side: Side.right, analogIndex: 1);

  bool get isConfigured {
    if (!_isInitialized) {
      throw Exception(
        'PositionsManager is not initialized. Call initialize() first.',
      );
    }

    return (!left.isEnabled || left.hasValue) &&
        (!right.isEnabled || right.hasValue);
  }
}
