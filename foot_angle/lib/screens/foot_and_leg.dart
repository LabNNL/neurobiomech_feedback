import 'dart:math';

import 'package:flutter/material.dart';

enum FootAndLegSide { left, right }

class FootAndLeg extends StatelessWidget {
  const FootAndLeg({
    super.key,
    required this.side,
    required this.angle,
    required this.targetAngle,
    required this.acceptedTolerance,
    required this.almostTolerance,
    this.acceptedColor = Colors.green,
    this.almostColor = Colors.orange,
    this.refusedColor = Colors.red,
    this.width,
    this.height,
  });

  final FootAndLegSide side;

  final double angle;
  final double targetAngle;
  final double acceptedTolerance;
  final double almostTolerance;
  final Color acceptedColor;
  final Color almostColor;
  final Color refusedColor;

  final double? width;
  final double? height;

  final mainOffset = 140.0;
  final dimensionSizedBox = const SizedBox(width: 600, height: 800);

  @override
  Widget build(BuildContext context) {
    final isAccepted =
        (angle >= targetAngle - acceptedTolerance) &&
        (angle <= targetAngle + acceptedTolerance);
    final isAlmost =
        !isAccepted &&
        (angle >= targetAngle - almostTolerance) &&
        (angle <= targetAngle + almostTolerance);

    return Transform.flip(
      flipX: side == FootAndLegSide.left,
      child: ConstraintsTransformBox(
        constraintsTransform: (constraints) => BoxConstraints(
          maxWidth: width ?? constraints.maxWidth,
          maxHeight: height ?? constraints.maxHeight,
        ),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Stack(
            children: [
              dimensionSizedBox,
              Positioned(
                left: mainOffset,
                child: Stack(
                  children: [
                    dimensionSizedBox,
                    Image.asset('assets/images/leg.png'),
                    _buildFoot(angle: angle),
                    //_buildFoot(angle: targetAngle, opacity: 0.4),
                    _buildFoot(
                      angle: targetAngle,
                      color: isAccepted
                          ? acceptedColor
                          : (isAlmost ? almostColor : refusedColor),
                      opacity: 0.4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoot({
    required double angle,
    Color? color,
    double opacity = 1.0,
  }) {
    return Positioned(
      left: 25,
      top: 430,
      child: Transform.rotate(
        angle: angle.isFinite ? -angle * pi / 180 : 0,
        origin: const Offset(-130, -70),
        child: Opacity(
          opacity: opacity,
          child: Image.asset('assets/images/foot.png', color: color),
        ),
      ),
    );
  }
}
