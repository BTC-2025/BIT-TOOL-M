import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

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
    // Completely preserve exact existing macOS desktop splash presentation
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return _buildDesktopSplash(context);
    }

    return _buildMobileSplash(context);
  }

  /// Refined, premium mobile startup experience for Android and iOS
  Widget _buildMobileSplash(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Premium light/dark brand colors
    final bgColor = isDark
        ? NeumorphicTheme.darkBg
        : const Color(0xFFF4F8FD);
    final cardBg = isDark ? const Color(0xFF161F30) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF24324C)
        : const Color(0xFFE2EAF4);
    final titleColor = isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF182338);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF78869A);
    final progressColor = isDark
        ? NeumorphicTheme.darkAccent
        : const Color(0xFF2563EB);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: bgColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0F1523), Color(0xFF0A0E18)],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF8FAFD), Color(0xFFEEF4FA)],
                  ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    if (reduceMotion) return child!;
                    return Opacity(
                      opacity: _opacityAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo container: modest circular surface with soft, restrained shadow
                      Container(
                        width: 124,
                        height: 124,
                        decoration: BoxDecoration(
                          color: cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cardBorder,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.45)
                                  : const Color(0xFF1B2A4A).withValues(alpha: 0.08),
                              offset: const Offset(0, 8),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: isDark
                                  ? const Color(0xFF1B2336).withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.9),
                              offset: const Offset(0, -2),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(22),
                        child: Image.asset(
                          'assets/bit_tool_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title: BIT TOOL (Deep navy, clean letter spacing)
                      Text(
                        'BIT TOOL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.2,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle: Integrated Enterprise Suite (Muted slate, comfortable spacing)
                      Text(
                        'Integrated Enterprise Suite',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Subtle brand-consistent loading indicator
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Exact previous macOS desktop splash layout
  Widget _buildDesktopSplash(BuildContext context) {
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
