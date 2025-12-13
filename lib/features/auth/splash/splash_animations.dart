import 'package:flutter/material.dart';

/// Splash Screen Animation Helpers
/// Custom animations for splash screen
/// 
/// Co-authored-by: Ali-0110
class SplashAnimations {
  /// Logo scale animation
  static Animation<double> createScaleAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(
          0.0,
          0.5,
          curve: Curves.easeOutBack,
        ),
      ),
    );
  }

  /// Logo rotation animation
  static Animation<double> createRotationAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(
          0.0,
          0.6,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  /// Fade in animation
  static Animation<double> createFadeAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(
          0.3,
          0.8,
          curve: Curves.easeIn,
        ),
      ),
    );
  }

  /// Slide up animation
  static Animation<Offset> createSlideAnimation(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(
          0.4,
          0.9,
          curve: Curves.easeOut,
        ),
      ),
    );
  }

  /// Pulsing animation for loading indicator
  static Animation<double> createPulseAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  /// Shimmer effect animation
  static Animation<double> createShimmerAnimation(AnimationController controller) {
    return Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.linear,
      ),
    );
  }

  /// Wave animation for background
  static Animation<double> createWaveAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  /// Bounce animation
  static Animation<double> createBounceAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.bounceOut,
      ),
    );
  }

  /// Elastic animation
  static Animation<double> createElasticAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ),
    );
  }

  /// Create staggered animation delays
  static List<Duration> createStaggeredDelays({
    required int count,
    Duration interval = const Duration(milliseconds: 100),
  }) {
    return List.generate(
      count,
      (index) => Duration(milliseconds: index * interval.inMilliseconds),
    );
  }

  /// Combined entrance animation
  static Widget buildEntranceAnimation({
    required Widget child,
    required Animation<double> animation,
    Offset? slideFrom,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: slideFrom ?? const Offset(0.0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
        ),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Animated logo with multiple effects
  static Widget buildAnimatedLogo({
    required AnimationController controller,
    required Widget logo,
  }) {
    final scaleAnimation = createScaleAnimation(controller);
    final rotationAnimation = createRotationAnimation(controller);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Transform.rotate(
            angle: rotationAnimation.value * 0.5,
            child: logo,
          ),
        );
      },
    );
  }

  /// Shimmer loading effect
  static Widget buildShimmerEffect({
    required AnimationController controller,
    required Widget child,
    Color? shimmerColor,
  }) {
    final shimmerAnimation = createShimmerAnimation(controller);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                shimmerAnimation.value - 0.3,
                shimmerAnimation.value,
                shimmerAnimation.value + 0.3,
              ],
              colors: [
                shimmerColor?.withOpacity(0.0) ?? Colors.white.withOpacity(0.0),
                shimmerColor?.withOpacity(0.5) ?? Colors.white.withOpacity(0.5),
                shimmerColor?.withOpacity(0.0) ?? Colors.white.withOpacity(0.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }

  /// Breathing/pulsing effect
  static Widget buildPulseEffect({
    required AnimationController controller,
    required Widget child,
  }) {
    final pulseAnimation = createPulseAnimation(controller);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.scale(
          scale: pulseAnimation.value,
          child: child,
        );
      },
    );
  }

  /// Typing text animation
  static String getTypingText(String text, Animation<double> animation) {
    final progress = animation.value;
    final displayLength = (text.length * progress).round();
    return text.substring(0, displayLength);
  }

  /// Create loading dots animation
  static Widget buildLoadingDots({
    required AnimationController controller,
    Color? color,
    double size = 8.0,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (controller.value - delay).clamp(0.0, 1.0);
            final scale = 1.0 + (0.5 * Curves.easeInOut.transform(value));
            
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color ?? Colors.white,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
