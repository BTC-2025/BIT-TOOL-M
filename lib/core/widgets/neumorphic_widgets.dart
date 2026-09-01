import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeumorphicDecoration {
  static BoxDecoration build({
    required BuildContext context,
    bool isDark = false,
    bool inset = false,
    double borderRadius = 16.0,
    Color? color,
  }) {
    final bool isAppDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = color ?? (isAppDark ? NeumorphicTheme.darkCard : NeumorphicTheme.lightCard);
    
    // Derived shadow colors
    final Color darkShadow = isAppDark ? NeumorphicTheme.darkDarkShadow : NeumorphicTheme.lightDarkShadow;
    final Color lightShadow = isAppDark ? NeumorphicTheme.darkLightShadow : NeumorphicTheme.lightLightShadow;

    // Linear gradient for premium surface light reflection
    final LinearGradient surfaceGradient = inset
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              darkShadow.withOpacity(isAppDark ? 0.3 : 0.15),
              bg,
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              lightShadow.withOpacity(isAppDark ? 0.05 : 0.9),
              bg,
              darkShadow.withOpacity(isAppDark ? 0.05 : 0.05),
            ],
            stops: const [0.0, 0.5, 1.0],
          );

    if (inset) {
      return BoxDecoration(
        color: bg,
        gradient: surfaceGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Top-left dark shadow (receding)
          BoxShadow(
            color: darkShadow.withOpacity(isAppDark ? 0.8 : 0.4),
            offset: const Offset(2, 2),
            blurRadius: 4,
            spreadRadius: -1,
          ),
          // Bottom-right light highlight
          BoxShadow(
            color: lightShadow.withOpacity(isAppDark ? 0.1 : 0.9),
            offset: const Offset(-2, -2),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      );
    } else {
      return BoxDecoration(
        color: bg,
        gradient: surfaceGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isAppDark ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          // Main drop shadow
          BoxShadow(
            color: darkShadow.withOpacity(isAppDark ? 0.6 : 0.35),
            offset: const Offset(6, 6),
            blurRadius: 16,
            spreadRadius: 0,
          ),
          // Ambient back light
          BoxShadow(
            color: lightShadow.withOpacity(isAppDark ? 0.08 : 0.9),
            offset: const Offset(-6, -6),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      );
    }
  }
}

class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final bool inset;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.color,
    this.inset = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: NeumorphicDecoration.build(
        context: context,
        inset: inset,
        borderRadius: borderRadius,
        color: color,
      ),
      child: child,
    );
  }
}

class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const NeumorphicButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    this.color,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    setState(() => _isPressed = true);
    _animationController.reverse();
  }

  void _handleTapUp() {
    setState(() => _isPressed = false);
    _animationController.forward();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: () => _handleTapCancel(),
      child: ScaleTransition(
        scale: _animationController,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: widget.padding,
          decoration: NeumorphicDecoration.build(
            context: context,
            inset: _isPressed,
            borderRadius: widget.borderRadius,
            color: widget.color,
          ),
          child: Center(
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class NeumorphicTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final bool obscureText;

  const NeumorphicTextField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.prefixIcon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: NeumorphicDecoration.build(
        context: context,
        inset: true,
        borderRadius: 14,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? NeumorphicTheme.darkText : NeumorphicTheme.lightText,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            color: (isDark ? NeumorphicTheme.darkText : NeumorphicTheme.lightText).withOpacity(0.4),
            fontSize: 15,
          ),
          icon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: (isDark ? NeumorphicTheme.darkAccent : NeumorphicTheme.lightAccent),
                  size: 20,
                )
              : null,
        ),
      ),
    );
  }
}
