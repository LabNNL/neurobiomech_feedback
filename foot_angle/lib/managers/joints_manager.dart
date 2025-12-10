import 'dart:convert';
import 'dart:io';

import 'package:frontend_fundamentals/utils/generic_listener.dart';
import 'package:path_provider/path_provider.dart';

enum Side {
  left,
  right;

  Map<String, dynamic> get serialized => {'value': name};

  static Side fromSerialized(
    Map<String, dynamic>? map, {
    required Side defaultValue,
  }) {
    return values.firstWhere(
      (side) => side.name == map?['value'] as String?,
      orElse: () => defaultValue,
    );
  }
}

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

  Map<String, dynamic> get serialized => {'value': name};

  static Joint fromSerialized(
    Map<String, dynamic>? map, {
    required Joint defaultValue,
  }) {
    return values.firstWhere(
      (joint) => joint.name == map?['value'] as String?,
      orElse: () => defaultValue,
    );
  }
}

class AngleController {
  AngleController({double? angle}) : _angle = angle;

  double? _angle;
  double? get angle => _angle;
  set angle(double? value) {
    _angle = value;
    JointsManager.instance._saveConfiguration();
  }

  bool get hasValue => _angle != null;

  Map<String, dynamic> get serialized {
    return {'angle': _angle};
  }

  AngleController.fromSerialized(Map<String, dynamic>? map)
    : _angle = (map?['angle'] as num?)?.toDouble();
}

class AnalogAngleController extends AngleController {
  AnalogAngleController({super.angle, double? voltage}) : _voltage = voltage;

  double? _voltage;
  double? get voltage => _voltage;
  set voltage(double? value) {
    _voltage = value;
    JointsManager.instance._saveConfiguration();
  }

  @override
  bool get hasValue => _voltage != null && angle != null;

  @override
  Map<String, dynamic> get serialized =>
      super.serialized..addAll({'voltage': _voltage});

  AnalogAngleController.fromSerialized(super.map)
    : _voltage = (map?['voltage'] as num?)?.toDouble(),
      super.fromSerialized();
}

class TargetAngleController extends AngleController {
  TargetAngleController({
    super.angle,
    double? tolerance,
    double? almostTolerance,
  }) : _tolerance = tolerance,
       _almostTolerance = almostTolerance;

  double? _tolerance;
  double? get tolerance => _tolerance;
  set tolerance(double? value) {
    _tolerance = value;
    JointsManager.instance._saveConfiguration();
  }

  double? _almostTolerance;
  double? get almostTolerance => _almostTolerance;
  set almostTolerance(double? value) {
    _almostTolerance = value;
    JointsManager.instance._saveConfiguration();
  }

  bool isAngleAccepted(double testAngle) {
    if (angle == null || _tolerance == null) return false;

    return (testAngle >= angle! - _tolerance!) &&
        (testAngle <= angle! + _tolerance!);
  }

  bool isAngleAlmostAccepted(double testAngle) {
    if (angle == null || _almostTolerance == null) return false;

    return (testAngle >= angle! - _almostTolerance!) &&
        (testAngle <= angle! + _almostTolerance!);
  }

  @override
  Map<String, dynamic> get serialized => super.serialized
    ..addAll({'tolerance': _tolerance, 'almost_tolerance': _almostTolerance});

  TargetAngleController.fromSerialized(super.map)
    : _tolerance = (map?['tolerance'] as num?)?.toDouble(),
      _almostTolerance = (map?['almost_tolerance'] as num?)?.toDouble(),
      super.fromSerialized();
}

class JointController {
  JointController({required Side side, required int? analogIndex})
    : _analogIndex = analogIndex,
      _lowest = AnalogAngleController(),
      _highest = AnalogAngleController(),
      _target = TargetAngleController();

  bool _enabled = true;
  bool get enabled => _enabled;
  set enabled(bool value) {
    _enabled = value;
    JointsManager.instance._saveConfiguration();
  }

  int? _analogIndex;
  int? get analogIndex => _analogIndex;
  set analogIndex(int? value) {
    _analogIndex = value;
    JointsManager.instance._saveConfiguration();
  }

  AnalogAngleController _lowest;
  AnalogAngleController get lowest => _lowest;
  set lowest(AnalogAngleController value) {
    _lowest = value;
    JointsManager.instance._saveConfiguration();
  }

  AnalogAngleController _highest;
  AnalogAngleController get highest => _highest;
  set highest(AnalogAngleController value) {
    _highest = value;
    JointsManager.instance._saveConfiguration();
  }

  TargetAngleController _target;
  TargetAngleController get target => _target;
  set target(TargetAngleController value) {
    _target = value;
    JointsManager.instance._saveConfiguration();
  }

  bool get hasValue =>
      _analogIndex != null &&
      _lowest.hasValue &&
      _highest.hasValue &&
      _target.hasValue;

  double angleFromVoltage(double voltage) => _linearInterpolate(
    voltage,
    _lowest.voltage,
    _highest.voltage,
    _lowest.angle,
    _highest.angle,
  );

  double voltageFromAngle(double angle) => _linearInterpolate(
    angle,
    _lowest.angle,
    _highest.angle,
    _lowest.voltage,
    _highest.voltage,
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

  Map<String, dynamic> get serialized {
    return {
      'enabled': _enabled,
      'analog_index': _analogIndex,
      'lowest': _lowest.serialized,
      'highest': _highest.serialized,
      'target': _target.serialized,
    };
  }

  JointController.fromSerialized(
    Map<String, dynamic>? map, {
    required Side defaultSide,
  }) : _enabled = map?['enabled'] as bool? ?? true,
       _analogIndex = int.tryParse(map?['analog_index']?.toString() ?? ''),
       _lowest = AnalogAngleController.fromSerialized(
         map?['lowest'] as Map<String, dynamic>?,
       ),
       _highest = AnalogAngleController.fromSerialized(
         map?['highest'] as Map<String, dynamic>?,
       ),
       _target = TargetAngleController.fromSerialized(
         map?['target'] as Map<String, dynamic>?,
       );
}

class JointsManager {
  JointsManager._();
  static final JointsManager instance = JointsManager._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    await _loadConfiguration();
    _isInitialized = true;
  }

  Future<File> get _configFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/NeurobioFeedback/joints_config.json';
    return File(path);
  }

  Future<void> _loadConfiguration() async {
    final file = await _configFile;
    if (await file.exists()) {
      final content =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      _joint = Joint.fromSerialized(
        content['joint'],
        defaultValue: Joint.ankle,
      );
      _left = JointController.fromSerialized(
        content['left'],
        defaultSide: Side.left,
      );
      _right = JointController.fromSerialized(
        content['right'],
        defaultSide: Side.right,
      );
    }
  }

  final onConfigurationChanged = GenericListener<Function()>();
  Future<void> _savingQueue = Future.value();
  Future<void> _saveConfiguration() {
    final content = JsonEncoder.withIndent('  ').convert(serialized);

    // Chain saves so they run sequentially
    _savingQueue = _savingQueue.then((_) async {
      final file = await _configFile;
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.writeAsString(content);
    });

    onConfigurationChanged.notifyListeners((callback) => callback());
    return _savingQueue;
  }

  Joint _joint = Joint.ankle;
  Joint get joint => _joint;
  set joint(Joint value) {
    _joint = value;
    JointsManager.instance._saveConfiguration();
  }

  JointController _left = JointController(side: Side.left, analogIndex: 0);
  JointController get left => _left;
  set left(JointController value) {
    _left = value;
    JointsManager.instance._saveConfiguration();
  }

  JointController _right = JointController(side: Side.right, analogIndex: 1);
  JointController get right => _right;
  set right(JointController value) {
    _right = value;
    JointsManager.instance._saveConfiguration();
  }

  bool get isConfigured {
    if (!_isInitialized) {
      throw Exception(
        'PositionsManager is not initialized. Call initialize() first.',
      );
    }

    return (!left.enabled || left.hasValue) &&
        (!right.enabled || right.hasValue);
  }

  Map<String, dynamic> get serialized => {
    'joint': _joint.serialized,
    'left': _left.serialized,
    'right': _right.serialized,
  };
}
