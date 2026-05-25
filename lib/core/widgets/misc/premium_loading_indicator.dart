import 'package:flutter/material.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';

class PremiumLoadingIndicator extends StatefulWidget {
  final double size;
  const PremiumLoadingIndicator({super.key, this.size = 60});

  @override
  State<PremiumLoadingIndicator> createState() =>
      _PremiumLoadingIndicatorState();
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

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
          return SizedBox(
            width: widget.size * 1.5,
            height: widget.size * 1.5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity:
                      (1.2 - _scaleAnimation.value) * _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value * 1.5,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.primary.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),

                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: widget.size * 0.8,
                    height: widget.size * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.primary.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
