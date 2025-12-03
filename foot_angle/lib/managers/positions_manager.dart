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

  final lowestLeftFoot = AnalogPositionController(emgIndex: 0);
  final highestLeftFoot = AnalogPositionController(emgIndex: 0);
  final targetLeftFoot = PositionController(emgIndex: 0);

  final lowestRightFoot = AnalogPositionController(emgIndex: 1);
  final highestRightFoot = AnalogPositionController(emgIndex: 1);
  final targetRightFoot = PositionController(emgIndex: 1);

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
