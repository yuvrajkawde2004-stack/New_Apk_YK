import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class TopCategoriesList extends StatelessWidget {
  const TopCategoriesList({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Categories',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          ...categories.map((c) => _CategoryBar(
            name: c['name'] as String,
            isUpward: c['trend'] == 'up',
            fillPercentage: c['value'] as double,
          )),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatefulWidget {
  final String name;
  final bool isUpward;
  final double fillPercentage;

  const _CategoryBar({
    required this.name,
    required this.isUpward,
    required this.fillPercentage,
  });

  @override
  State<_CategoryBar> createState() => _CategoryBarState();
}

class _CategoryBarState extends State<_CategoryBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.isUpward ? 1200 : 800),
    );

    _widthAnimation = Tween<double>(begin: 0, end: widget.fillPercentage).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.isUpward ? Curves.fastOutSlowIn : Curves.bounceOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeInOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.name,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              Icon(
                widget.isUpward ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: widget.isUpward ? AppColors.emeraldGreen : AppColors.softOrange,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 12,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final currentWidth = constraints.maxWidth * _widthAnimation.value;
                      final showGlow = widget.isUpward && _controller.isAnimating;
                      final showBrake = !widget.isUpward && _controller.isCompleted;

                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerRight,
                        children: [
                          Container(
                            height: 12,
                            width: currentWidth,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.isUpward
                                    ? [AppColors.emeraldGreen.withValues(alpha: 0.5), AppColors.emeraldGreen]
                                    : [AppColors.softOrange.withValues(alpha: 0.5), AppColors.softOrange],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: showGlow
                                  ? [
                                      BoxShadow(
                                        color: AppColors.emeraldGreen.withValues(alpha: 0.6),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                          if (currentWidth > 0)
                            Positioned(
                              right: -4,
                              child: Transform.scale(
                                scale: showBrake ? _pulseAnimation.value : 1.0,
                                child: Container(
                                  width: 8,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.isUpward ? AppColors.emeraldGreen : AppColors.softOrange,
                                        blurRadius: 4,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
