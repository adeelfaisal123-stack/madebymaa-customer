import 'package:flutter/material.dart';

/// Slide-in route for dish detail — enters from the left (moves right).
abstract final class DishDetailRoute {
  static Route<T> push<T>(Widget screen) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (_, _, _) => screen,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final underlay = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0.1, 0),
          ).animate(underlay),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
