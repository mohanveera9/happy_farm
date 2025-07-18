import 'dart:async';
import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/banner_model.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/banner_service.dart';

class AutoScrollBannerWidget extends StatefulWidget {
  final double height;
  final Duration autoScrollDuration;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;
  final VoidCallback? onBannerTap;

  const AutoScrollBannerWidget({
    Key? key,
    this.height = 180.0,
    this.autoScrollDuration = const Duration(seconds: 3),
    this.borderRadius,
    this.margin,
    this.onBannerTap,
  }) : super(key: key);

  @override
  State<AutoScrollBannerWidget> createState() => _AutoScrollBannerWidgetState();
}

class _AutoScrollBannerWidgetState extends State<AutoScrollBannerWidget> {
  List<BannerModel> _banners = [];
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;
  final BannerService _bannerService = BannerService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchBanners() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final banners = await _bannerService.fetchMainBanners();
      
      if (!mounted) return;
      
      setState(() {
        _banners = banners;
        _isLoading = false;
      });
      
      if (_banners.isNotEmpty) {
        _startAutoScroll();
      }
    } catch (e) {
      print('Error fetching banners: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoScrollDuration, (timer) {
      if (_banners.isEmpty || !mounted) return;

      int nextPage = _currentIndex + 1;
      if (nextPage >= _banners.length) {
        _pageController.jumpToPage(0);
        _currentIndex = 0;
      } else {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _currentIndex = nextPage;
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: _isLoading
          ? _buildLoadingState()
          : _banners.isEmpty
              ? _buildEmptyState()
              : _buildBannerCarousel(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: widget.margin ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12.0),
        color: Colors.grey[200],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: widget.margin ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12.0),
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Text(
          'No banners available',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: widget.onBannerTap,
                child: Container(
                  margin: widget.margin ?? const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: widget.borderRadius ?? BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: widget.borderRadius ?? BorderRadius.circular(12.0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _banners[index].images.first,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.error_outline,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                              ),
                            );
                          },
                        ),
                        // Optional overlay for better text readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Page indicators
        if (_banners.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _banners.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == entry.key
                        ? Theme.of(context).primaryColor
                        : Colors.grey.withOpacity(0.4),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}