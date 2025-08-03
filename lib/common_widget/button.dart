import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';

class AboGlumboButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final Color? color;
  final double height;
  final double width;
  const AboGlumboButton({
    super.key,
    this.text,
    this.onPressed,
    this.color,
    this.height = 48.0,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: color ?? AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              text ?? 'Button',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
