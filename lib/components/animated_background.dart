import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class AnimatedBackground extends StatelessWidget {
  final Widget child;
  final bool useBlur;
  final double blurSigma;
  final Color? overlayColor;

  const AnimatedBackground({
    Key? key,
    required this.child,
    this.useBlur = true,
    this.blurSigma = 30.0,
    this.overlayColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated shapes background
        const Positioned.fill(
          child: RiveAnimation.asset(
            "assets/RiveAssets/shapes.riv",
            fit: BoxFit.cover,
          ),
        ),

        // Blur filter for the animation
        if (useBlur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: blurSigma,
                sigmaY: blurSigma,
              ),
              child: Container(
                color: overlayColor ?? Colors.transparent,
              ),
            ),
          ),

        // The actual content of the screen
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
