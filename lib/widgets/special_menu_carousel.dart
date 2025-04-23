import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../models/menu_item.dart';
import '../theme.dart';
import 'dart:async';

class SpecialMenuCarousel extends StatefulWidget {
  final List<MenuItem> specialMenus;
  final Function(MenuItem) onItemTap;

  const SpecialMenuCarousel({
    super.key,
    required this.specialMenus,
    required this.onItemTap,
  });

  @override
  State<SpecialMenuCarousel> createState() => _SpecialMenuCarouselState();
}

class _SpecialMenuCarouselState extends State<SpecialMenuCarousel>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _scaleController;
  int _currentIndex = 0;
  Timer? _autoPlayTimer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.92);
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _startAutoPlay();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isUserInteracting && mounted && widget.specialMenus.length > 1) {
        final nextPage = (_currentIndex + 1) % widget.specialMenus.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  Widget _buildCarouselItem(
    BuildContext context,
    MenuItem menu,
    int index,
    BoxConstraints constraints,
  ) {
    final isCurrentPage = index == _currentIndex;

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
        }

        return Transform.scale(
          scale: Curves.easeOutCubic.transform(isCurrentPage ? 1.0 : 0.9),
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _stopAutoPlay(),
        onTapUp: (_) => _startAutoPlay(),
        onTap: () => widget.onItemTap(menu),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth > 600 ? 25 : 15,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), // Reduced border radius
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20), // Reduced border radius
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image layer
                Image.asset(
                  menu.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Image not found',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Gradient overlay layer
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
                // Feature badge
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFE53935,
                      ), // Changed from blue to red
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          menu.price >= 30 ? '🔥 Featured' : '🌟 Recommended',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Menu item information
                Positioned(
                  left: 15,
                  right: 15,
                  bottom: 15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        menu.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4.0,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RM ${menu.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 2.0,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.specialMenus.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;
        final carouselHeight = isDesktop ? 240.0 : 200.0; // Increased height

        return Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: carouselHeight,
              child: GestureDetector(
                onHorizontalDragStart: (_) {
                  _isUserInteracting = true;
                  _stopAutoPlay();
                },
                onHorizontalDragEnd: (_) {
                  _isUserInteracting = false;
                  _startAutoPlay();
                },
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemCount: widget.specialMenus.length,
                      itemBuilder:
                          (context, index) => _buildCarouselItem(
                            context,
                            widget.specialMenus[index],
                            index,
                            constraints,
                          ),
                    ),
                    if (widget.specialMenus.length > 1) ...[
                      // Navigation buttons
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCubic,
                              );
                            },
                            color: Colors.red,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCubic,
                              );
                            },
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.specialMenus.length > 1) ...[
              const SizedBox(height: 12),
              AnimatedSmoothIndicator(
                activeIndex: _currentIndex,
                count: widget.specialMenus.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: const Color(0xFFE53935),
                  dotColor: Colors.grey.withOpacity(0.5),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
