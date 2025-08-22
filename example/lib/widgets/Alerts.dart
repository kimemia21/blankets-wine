import 'package:flutter/material.dart';

void showalert({
  required bool success,
  required BuildContext context,
  required String title,
  required String subtitle,
  int durationSeconds = 5,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => ModernAlert(
      success: success,
      title: title,
      subtitle: subtitle,
      onDismiss: () => overlayEntry.remove(),
    ),
  );

  overlay.insert(overlayEntry);

  // Auto dismiss after duration
  Future.delayed(Duration(seconds: durationSeconds), () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
}

class ModernAlert extends StatefulWidget {
  final bool success;
  final String title;
  final String subtitle;
  final VoidCallback onDismiss;

  const ModernAlert({
    super.key,
    required this.success,
    required this.title,
    required this.subtitle,
    required this.onDismiss,
  });

  @override
  State<ModernAlert> createState() => _ModernAlertState();
}

class _ModernAlertState extends State<ModernAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _animationController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;
    
    // Responsive sizing
    final alertWidth = isDesktop 
        ? 400.0 
        : isTablet 
            ? screenSize.width * 0.7 
            : screenSize.width * 0.9;
    
    final topPadding = MediaQuery.of(context).padding.top;
    final alertMargin = isDesktop ? 40.0 : isTablet ? 30.0 : 20.0;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          top: topPadding + alertMargin + (_slideAnimation.value * 100),
          left: (screenSize.width - alertWidth) / 2,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _dismiss,
                child: Container(
                  width: alertWidth,
                  constraints: BoxConstraints(
                    minHeight: isDesktop ? 120 : isTablet ? 110 : 100,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.success
                          ? [
                              const Color(0xFF4CAF50).withOpacity(0.95),
                              const Color(0xFF388E3C).withOpacity(0.95),
                            ]
                          : [
                              const Color(0xFFF44336).withOpacity(0.95),
                              const Color(0xFFD32F2F).withOpacity(0.95),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.success ? Colors.green : Colors.red)
                            .withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Glassmorphism effect
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        // Main content
                        Padding(
                          padding: EdgeInsets.all(isDesktop ? 20 : isTablet ? 18 : 16),
                          child: Row(
                            children: [
                              // Icon container with animation
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.elasticOut,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: isDesktop ? 50 : isTablet ? 45 : 40,
                                      height: isDesktop ? 50 : isTablet ? 45 : 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        widget.success 
                                            ? Icons.check_circle_rounded 
                                            : Icons.error_rounded,
                                        color: Colors.white,
                                        size: isDesktop ? 28 : isTablet ? 25 : 22,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: isDesktop ? 16 : isTablet ? 14 : 12),
                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isDesktop ? 18 : isTablet ? 16 : 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (widget.subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.subtitle,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Close button
                              GestureDetector(
                                onTap: _dismiss,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white.withOpacity(0.8),
                                    size: isDesktop ? 22 : isTablet ? 20 : 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Progress indicator
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1.0, end: 0.0),
                            duration: const Duration(seconds: 3),
                            builder: (context, progress, child) {
                              return LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.3),
                                ),
                                minHeight: 3,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

