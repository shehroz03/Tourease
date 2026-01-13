import 'package:flutter/material.dart';
import 'dart:ui';

class ThemedBackground extends StatelessWidget {
  final Widget child;
  final bool useImage;
  final String? imageUrl;
  final bool showBlur;

  const ThemedBackground({
    super.key,
    required this.child,
    this.useImage = false,
    this.imageUrl,
    this.showBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Layer: Gradient or Image
        Positioned.fill(
          child: useImage
              ? Image.network(
                  imageUrl ??
                      'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=1400&q=60',
                  fit: BoxFit.cover,
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.05),
                        Theme.of(context).colorScheme.surface,
                        Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
        ),

        // Blur Layer (if image is used for glassmorphism effect)
        if (useImage || showBlur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ),

        // Gradient Overlay for readability
        if (useImage)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),

        // Content
        SafeArea(child: child),
      ],
    );
  }
}
