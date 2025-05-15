import 'dart:math';
import 'package:flutter/material.dart';

/// A utility class for generating colorful animated avatar images
class AvatarGenerator {
  // Color pairs for vibrant gradients (background, foreground)
  static const List<List<Color>> _colorPairs = [
    [Color(0xFF3D5AF1), Color(0xFF22B07D)], // Blue and Green
    [Color(0xFFFF5F6D), Color(0xFFFFC371)], // Red and Orange
    [Color(0xFF00B4DB), Color(0xFF0083B0)], // Light Blue and Dark Blue
    [Color(0xFFEC008C), Color(0xFFFC6767)], // Pink and Salmon
    [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Purple shades
    [Color(0xFF02AABD), Color(0xFF00CDAC)], // Teal shades
    [Color(0xFFFF512F), Color(0xFFDD2476)], // Orange and Pink
    [Color(0xFF373B44), Color(0xFF4286F4)], // Dark and Blue
    [Color(0xFF834D9B), Color(0xFFD04ED6)], // Purple shades
    [Color(0xFF009245), Color(0xFFFFED00)], // Green and Yellow
  ];

  /// Randomly select a color pair for an avatar
  static List<Color> getRandomColorPair() {
    final random = Random();
    return _colorPairs[random.nextInt(_colorPairs.length)];
  }

  /// Get a color pair based on a string (e.g., book title)
  static List<Color> getColorPairFromString(String text) {
    // Use the hash code of the string to get a deterministic color pair
    int hashCode = text.hashCode.abs();
    return _colorPairs[hashCode % _colorPairs.length];
  }

  /// Get the first letter from a string, with fallback
  static String getInitial(String text) {
    if (text.isEmpty) return '?';
    return text[0].toUpperCase();
  }

  /// Get a simple Widget that shows a book-like avatar with the initial
  static Widget buildSimpleAvatar(String text, {double size = 150}) {
    final List<Color> colors = getColorPairFromString(text);
    final String initial = getInitial(text);

    return Container(
      width: size,
      height: size * 1.33, // Book-like proportions (3:4)
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(size * 0.25),
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(size * 0.15),
              ),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  initial,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: size * 0.05),
                Container(
                  width: size * 0.6,
                  height: 2,
                  color: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get an animated Widget that shows a book-like avatar with the initial
  static Widget buildAnimatedAvatar(String text, {double size = 150}) {
    return AnimatedAvatar(text: text, size: size);
  }
}

/// An animated avatar widget that continually shifts the gradient colors
class AnimatedAvatar extends StatefulWidget {
  final String text;
  final double size;

  const AnimatedAvatar({
    Key? key,
    required this.text,
    this.size = 150,
  }) : super(key: key);

  @override
  State<AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<AnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<Color> _colors;

  @override
  void initState() {
    super.initState();

    // Get colors based on text
    _colors = AvatarGenerator.getColorPairFromString(widget.text);

    // Setup animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String initial = AvatarGenerator.getInitial(widget.text);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size * 1.33, // Book-like proportions
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _colors[0],
                Color.lerp(_colors[0], _colors[1], _animation.value)!,
                _colors[1],
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Animated decorative elements
              Positioned(
                right: 0,
                top: widget.size * 0.1 * _animation.value,
                child: Container(
                  width: widget.size * 0.5,
                  height: widget.size * 0.5,
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withOpacity(0.1 + 0.05 * _animation.value),
                    borderRadius: BorderRadius.circular(widget.size * 0.25),
                  ),
                ),
              ),
              Positioned(
                left: 10 + widget.size * 0.05 * _animation.value,
                bottom: 10 + widget.size * 0.05 * _animation.value,
                child: Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withOpacity(0.1 + 0.05 * _animation.value),
                    borderRadius: BorderRadius.circular(widget.size * 0.15),
                  ),
                ),
              ),

              // Book spine
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: widget.size * 0.1,
                child: Container(
                  decoration: BoxDecoration(
                    color: _colors[1].withOpacity(0.7),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                ),
              ),

              // Center content with the text initial
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      initial,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.size * 0.4,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: widget.size * 0.05),
                    Container(
                      width: widget.size * (0.5 + 0.1 * _animation.value),
                      height: 2,
                      color: Colors.white
                          .withOpacity(0.5 + 0.2 * _animation.value),
                    ),
                    SizedBox(height: widget.size * 0.1),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          widget.text.length > 15
                              ? widget.text.substring(0, 15) + "..."
                              : widget.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.size * 0.12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
