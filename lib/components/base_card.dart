import 'package:flutter/material.dart';

class Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final ShapeBorder? shape;
  final double? elevation;
  final Clip clipBehavior;

  const Card({
    super.key,
    required this.child,
    this.margin,
    this.color,
    this.shape,
    this.elevation,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      child: Material(
        shadowColor: const Color.fromARGB(255, 253, 120, 129),
        color: color ?? Colors.white,
        shape: shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        elevation: elevation ?? 3.0,
        clipBehavior: clipBehavior,
        child: child,
      ),
    );
  }
}
