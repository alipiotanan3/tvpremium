import 'package:flutter/material.dart';

class CustomCarousel extends StatefulWidget {
  final List<dynamic> items;
  final Widget Function(BuildContext context, dynamic item, int index) itemBuilder;
  final double? height;
  final double? width;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Duration autoPlayAnimationDuration;
  final Curve autoPlayCurve;

  const CustomCarousel({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.height,
    this.width,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.autoPlayAnimationDuration = const Duration(milliseconds: 800),
    this.autoPlayCurve = Curves.fastOutSlowIn,
  });

  @override
  State<CustomCarousel> createState() => _CustomCarouselState();
}

class _CustomCarouselState extends State<CustomCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    if (widget.autoPlay) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    Future.delayed(widget.autoPlayInterval, () {
      if (mounted) {
        if (_currentPage < widget.items.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: widget.autoPlayAnimationDuration,
          curve: widget.autoPlayCurve,
        );
        _startAutoPlay();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.items.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          return AnimatedScale(
            scale: index == _currentPage ? 1.0 : 0.9,
            duration: const Duration(milliseconds: 300),
            child: widget.itemBuilder(context, widget.items[index], index),
          );
        },
      ),
    );
  }
} 