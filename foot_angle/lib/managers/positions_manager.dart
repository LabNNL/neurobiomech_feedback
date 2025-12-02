class PositionController {
  PositionController({required this.emgIndex});

  int emgIndex;

  double? voltage;
  double? angle;
  bool get hasPosition => voltage != null && angle != null;
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

  final highestLeftFoot = PositionController(emgIndex: 0);
  final highestRightFoot = PositionController(emgIndex: 1);
  final lowestLeftFoot = PositionController(emgIndex: 0);
  final lowestRightFoot = PositionController(emgIndex: 1);

  bool get isConfigured {
    if (!_isInitialized) {
      throw Exception(
        'PositionsManager is not initialized. Call initialize() first.',
      );
    }

    return highestLeftFoot.hasPosition &&
        highestRightFoot.hasPosition &&
        lowestLeftFoot.hasPosition &&
        lowestRightFoot.hasPosition;
  }
}
