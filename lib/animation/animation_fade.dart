import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

enum AnimationType { opacity, translateX }

class FadeAnimation extends StatelessWidget {
  final double delay;
  final Widget child;

  /// Traccar backend entity identifier (e.g. deviceId, positionId, timestamp)
  /// Used to control smooth re-triggering when live Traccar websocket/REST data changes
  final Object? traccarEntityId;

  const FadeAnimation(
    this.delay,
    this.child, {
    Key? key,
    this.traccarEntityId,
  }) : super(key: key);

  /// Dedicated named constructor for Traccar API dynamic entities (/api/devices, /api/positions)
  factory FadeAnimation.traccar({
    required double delay,
    required Widget child,
    required Object entityId,
    Key? key,
  }) {
    return FadeAnimation(
      delay,
      child,
      key: key ?? ValueKey('traccar_fade_$entityId'),
      traccarEntityId: entityId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final MovieTween tween = MovieTween()
      ..tween(
        AnimationType.opacity,
        Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
      )
      ..tween(
        AnimationType.translateX,
        Tween(begin: 30.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
      );

    return PlayAnimationBuilder<Movie>(
      key: traccarEntityId != null ? ValueKey(traccarEntityId) : null,
      delay: Duration(milliseconds: (500 * delay).round()),
      tween: tween,
      duration: tween.duration,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value.get(AnimationType.opacity),
        child: Transform.translate(
          offset: Offset(value.get(AnimationType.translateX), 0),
          child: child,
        ),
      ),
    );
  }
}
