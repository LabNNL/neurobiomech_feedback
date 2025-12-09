import 'dart:math';

import 'package:flutter/material.dart';
import 'package:foot_angle/managers/joints_manager.dart';

class JointPainter extends StatelessWidget {
  const JointPainter({
    super.key,
    required this.controller,
    required this.angle,
    this.acceptedColor = Colors.green,
    this.almostColor = Colors.orange,
    this.refusedColor = Colors.red,
    this.constraints,
  });

  final JointController controller;
  final double angle;

  final Color acceptedColor;
  final Color almostColor;
  final Color refusedColor;

  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: controller.side == Side.left,
      child: ConstraintsTransformBox(
        constraintsTransform: (cnts) => BoxConstraints(
          maxWidth: constraints?.maxWidth ?? cnts.maxWidth,
          maxHeight: constraints?.maxHeight ?? cnts.maxHeight,
        ),
        child: FittedBox(
          fit: BoxFit.contain,
          child: _AnklePainter(
            controller: controller,
            angle: angle,
            acceptedColor: acceptedColor,
            almostColor: almostColor,
            refusedColor: refusedColor,
          ),
        ),
      ),
    );
  }
}

class _AnklePainter extends StatelessWidget {
  const _AnklePainter({
    required this.controller,
    required this.angle,
    required this.acceptedColor,
    required this.almostColor,
    required this.refusedColor,
  });

  final JointController controller;
  final double angle;

  final Color acceptedColor;
  final Color almostColor;
  final Color refusedColor;

  @override
  Widget build(BuildContext context) {
    final isAccepted = controller.target.isAngleAccepted(angle);
    final isAlmostAccepted = controller.target.isAngleAlmostAccepted(angle);

    final mainOffset = 130.0;
    final dimensionSizedBox = const SizedBox(width: 700, height: 850);

    return Stack(
      children: [
        dimensionSizedBox,
        Positioned(
          left: mainOffset,
          child: Stack(
            children: [
              dimensionSizedBox,
              Image.asset('assets/images/ankle_shank.png'),
              _buildFoot(angle: angle),
              _buildFoot(
                angle: controller.target.angle ?? 0.0,
                color: isAccepted
                    ? acceptedColor
                    : (isAlmostAccepted ? almostColor : refusedColor),
                opacity: 0.4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFoot({
    required double angle,
    Color? color,
    double opacity = 1.0,
  }) {
    return Positioned(
      left: 34,
      top: 445,
      child: Transform.rotate(
        angle: angle.isFinite ? -angle * pi / 180 : 0,
        origin: const Offset(-130, -70),
        child: Opacity(
          opacity: opacity,
          child: Image.asset('assets/images/ankle_foot.png', color: color),
        ),
      ),
    );
  }
}
