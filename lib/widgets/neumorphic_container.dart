import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable neumorphic container supporting convex (raised) and concave (pressed) states
class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final bool isConvex;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? width;
  final double? height;

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.isConvex = true,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.color,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? AppColors.secondarySurface;
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isConvex
            ? [
                BoxShadow(
                  color: AppColors.shadowDark.withValues(alpha: 0.5),
                  offset: const Offset(4, 4),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: AppColors.shadowLight.withValues(alpha: 0.05),
                  offset: const Offset(-3, -3),
                  blurRadius: 6,
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.shadowDark.withValues(alpha: 0.3),
                  offset: const Offset(-2, -2),
                  blurRadius: 6,
                ),
                BoxShadow(
                  color: AppColors.shadowLight.withValues(alpha: 0.03),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
      ),
      child: child,
    );
  }
}
