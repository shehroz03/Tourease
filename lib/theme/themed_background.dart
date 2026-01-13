import 'package:flutter/material.dart';
import 'dart:ui';

class _AnimatedParticle extends StatefulWidget {
  final Color color;
  const _AnimatedParticle({required this.color});

  @override
  State<_AnimatedParticle> createState() => _AnimatedParticleState();
}

class _AnimatedParticleState extends State<_AnimatedParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _top;
  late Animation<double> _left;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10 + (DateTime.now().millisecond % 10)),
    )..repeat(reverse: true);

    _top = Tween<double>(
      begin: 0.1,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _left = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * _top.value,
          left: MediaQuery.of(context).size.width * _left.value,
          child: child!,
        );
      },
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.05),
        ),
      ),
    );
  }
}

class ThemedBackground extends StatelessWidget {
  final Widget child;
  final bool useImage;
  final String? imageUrl;
  final bool showBlur;
  final bool isProfessional;

  const ThemedBackground({
    super.key,
    required this.child,
    this.useImage = false,
    this.imageUrl,
    this.showBlur = false,
    this.isProfessional = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isProfessional) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D47A1), // Deep Blue
                Color(0xFF1976D2), // Medium Blue
                Color(0xFF42A5F5), // Light Blue
              ],
            ),
          ),
          child: Stack(
            children: [
              const _AnimatedParticle(color: Colors.white),
              const _AnimatedParticle(color: Colors.white70),
              const _AnimatedParticle(color: Colors.blueAccent),
              SafeArea(child: child),
            ],
          ),
        ),
      );
    }

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
