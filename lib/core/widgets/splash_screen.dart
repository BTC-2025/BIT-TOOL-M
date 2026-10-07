import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'responsive_shell.dart';

class SplashScreen extends StatefulWidget {
  final Duration duration;
  final Widget? nextScreen;

  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 1600),
    this.nextScreen,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    _timer = Timer(widget.duration, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: widget.nextScreen ?? const ResponsiveShell(),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? NeumorphicTheme.darkBg : NeumorphicTheme.lightBg;
    final cardColor = isDark
        ? NeumorphicTheme.darkCard
        : NeumorphicTheme.lightCard;
    final shadowDark = isDark
        ? NeumorphicTheme.darkDarkShadow
        : NeumorphicTheme.lightDarkShadow;
    final shadowLight = isDark
        ? NeumorphicTheme.darkLightShadow
        : NeumorphicTheme.lightLightShadow;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: shadowDark.withValues(alpha: 0.7),
                      offset: const Offset(8, 8),
                      blurRadius: 16,
                    ),
                    BoxShadow(
                      color: shadowLight.withValues(alpha: 0.9),
                      offset: const Offset(-8, -8),
                      blurRadius: 16,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Image.asset(
                  'assets/bit_tool_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'BIT TOOL',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Integrated Enterprise Suite',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
