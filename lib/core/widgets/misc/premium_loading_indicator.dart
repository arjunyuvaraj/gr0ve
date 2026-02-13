import 'package:flutter/material.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';

class PremiumLoadingIndicator extends StatefulWidget {
  final double size;
  const PremiumLoadingIndicator({super.key, this.size = 60});

  @override
  State<PremiumLoadingIndicator> createState() => _PremiumLoadingIndicatorState();
}

class _PremiumLoadingIndicatorState extends State<PremiumLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutExpo),
    );

    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.primary.withOpacity(0.1),
            ),
            padding: const EdgeInsets.all(12),
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Image.asset(
                  'assets/logo.png', // Fallback to a simple container if logo missing
                  errorBuilder: (context, _, __) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
