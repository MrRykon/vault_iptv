import 'package:flutter/material.dart';

/// A finite entrance animation that follows the device's motion preference.
class VaultReveal extends StatelessWidget {
  final Widget child;
  const VaultReveal({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)), child: child),
      ),
    );
  }
}
