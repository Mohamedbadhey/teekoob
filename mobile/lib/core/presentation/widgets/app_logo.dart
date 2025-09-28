import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool showShadow;
  final Color? shadowColor;
  final double shadowBlur;
  final Offset shadowOffset;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 20.0,
    this.showShadow = true,
    this.shadowColor,
    this.shadowBlur = 20.0,
    this.shadowOffset = const Offset(0, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      constraints: BoxConstraints(
        maxWidth: width ?? 150,
        maxHeight: height ?? 150,
        minWidth: (width ?? 150) * 0.6,
        minHeight: (height ?? 150) * 0.6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), // Add white background for better visibility
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: (shadowColor ?? Theme.of(context).colorScheme.primary)
                      .withOpacity(0.4), // Increased shadow opacity
                  blurRadius: shadowBlur,
                  offset: shadowOffset,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1), // Add subtle black shadow
                  blurRadius: shadowBlur * 0.5,
                  offset: Offset(shadowOffset.dx * 0.5, shadowOffset.dy * 0.5),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width ?? 120,
              height: height ?? 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Icon(
                Icons.book,
                size: ((width ?? 120) + (height ?? 120)) / 4,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            );
          },
        ),
      ),
    );
  }
}

// Predefined logo sizes for common use cases
class AppLogoSmall extends StatelessWidget {
  const AppLogoSmall({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLogo(
      width: 80,
      height: 80,
      borderRadius: 16.0,
      shadowBlur: 15.0,
      shadowOffset: Offset(0, 8),
    );
  }
}

class AppLogoMedium extends StatelessWidget {
  const AppLogoMedium({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLogo(
      width: 120,
      height: 120,
      borderRadius: 20.0,
      shadowBlur: 20.0,
      shadowOffset: Offset(0, 10),
    );
  }
}

class AppLogoLarge extends StatelessWidget {
  const AppLogoLarge({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLogo(
      width: 150,
      height: 150,
      borderRadius: 25.0,
      shadowBlur: 25.0,
      shadowOffset: Offset(0, 12),
    );
  }
}
