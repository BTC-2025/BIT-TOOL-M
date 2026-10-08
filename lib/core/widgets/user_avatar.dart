import 'package:flutter/material.dart';
import '../models/user_model.dart';

/// Reusable user avatar supporting network images with seamless fallback to initials.
class UserAvatar extends StatelessWidget {
  final UserModel? user;
  final double radius;
  final double? fontSize;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 16,
    this.fontSize,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        backgroundColor ??
        (isDark ? const Color(0xFF2563EB) : const Color(0xFF0F172A));

    if (user != null && user!.hasValidProfilePicture) {
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: Image.network(
            user!.profilePictureUrl!.trim(),
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallback(bgColor);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildFallback(bgColor);
            },
          ),
        ),
      );
    }

    return _buildFallback(bgColor);
  }

  Widget _buildFallback(Color bgColor) {
    final initials = user?.initials ?? 'U';
    final effectiveFontSize = fontSize ?? (radius * 0.85);

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: effectiveFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
