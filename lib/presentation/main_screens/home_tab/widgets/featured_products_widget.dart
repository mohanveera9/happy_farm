// FeaturedProductsWidget with Shimmer Loading States
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/product_model.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/product_service.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/product_card.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';

class FeaturedProductsWidget extends StatefulWidget {
  final Function(dynamic product) onProductTap;
  final ScrollController? parentScrollController;
  final int initialVisibleCount;

  const FeaturedProductsWidget({
    Key? key,
    required this.onProductTap,
    this.parentScrollController,
    this.initialVisibleCount = 4,
  }) : super(key: key);

  @override
  State<FeaturedProductsWidget> createState() => _FeaturedProductsWidgetState();
}

class _FeaturedProductsWidgetState extends State<FeaturedProductsWidget> {
  final ProductService _productService = ProductService();

  List<FeaturedProduct> _featuredProducts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;
  int _currentPage = 1;
  final int _perPage = 10;
  int _totalPages = 0;
  int _totalProducts = 0;
  bool _isLastPage = false;

  late ScrollController _horizontalScrollController;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _setupScrollListener();
    _fetchFeaturedProducts();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _horizontalScrollController.addListener(() {
      // Load more products when user scrolls near the end
      if (_horizontalScrollController.position.pixels >=
          _horizontalScrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore && _hasMoreProducts && !_isLastPage) {
          _loadMoreProducts();
        }
      }
    });
  }

  Future<void> _fetchFeaturedProducts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _productService.getFeaturedProductsWithPagination(
        page: _currentPage,
        perPage: _perPage,
      );

      print("Featured products initial fetch response: $response");

      setState(() {
        _featuredProducts = response['products'] ?? [];
        _totalPages = response['totalPages'] ?? 0;
        _totalProducts = response['totalProducts'] ?? 0;
        _isLoading = false;
        _hasMoreProducts = _currentPage < _totalPages;
        _isLastPage = _currentPage >= _totalPages;
      });

      // Pre-cache product images for better performance
      _preCacheProductImages();

      print(
          "Featured products - Products: ${_featuredProducts.length}, Total Pages: $_totalPages, Current Page: $_currentPage");
    } catch (e) {
      print('Error fetching featured products: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showErrorSnackbar(context, 'Failed to load featured products');
      }
    }
  }

  // Pre-cache product images to improve performance
  void _preCacheProductImages() {
    for (final product in _featuredProducts) {
      for (final imageUrl in product.images) {
        if (imageUrl.isNotEmpty) {
          precacheImage(
            CachedNetworkImageProvider(imageUrl),
            context,
          );
        }
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts || _isLastPage) {
      print(
          "Featured load more blocked: Loading: $_isLoadingMore, Has more: $_hasMoreProducts, Is last: $_isLastPage");
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;

      print("Loading featured products page $nextPage of $_totalPages");

      if (nextPage > _totalPages) {
        setState(() {
          _hasMoreProducts = false;
          _isLastPage = true;
        });
        return;
      }

      final response = await _productService.getFeaturedProductsWithPagination(
        page: nextPage,
        perPage: _perPage,
      );

      print("Featured load more response: $response");

      final newProducts = response['products'] ?? [];

      setState(() {
        if (newProducts.isNotEmpty) {
          _featuredProducts.addAll(newProducts);
          _currentPage = nextPage;
          print(
              "Added ${newProducts.length} featured products. Total now: ${_featuredProducts.length}");
        }

        _isLastPage = nextPage >= _totalPages;
        _hasMoreProducts = nextPage < _totalPages;
      });

      // Pre-cache new product images
      if (newProducts.isNotEmpty) {
        for (final product in newProducts) {
          for (final imageUrl in product.images) {
            if (imageUrl.isNotEmpty) {
              precacheImage(
                CachedNetworkImageProvider(imageUrl),
                context,
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error loading more featured products: $e');
      if (mounted) {
        showErrorSnackbar(context, 'Failed to load more featured products');
      }
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> refreshFeaturedProducts() async {
    setState(() {
      _featuredProducts = [];
      _currentPage = 1;
      _hasMoreProducts = true;
      _isLoadingMore = false;
      _totalPages = 0;
      _totalProducts = 0;
      _isLastPage = false;
    });
    await _fetchFeaturedProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmerLoadingState();
    }

    if (_featuredProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No featured products available.'),
        ),
      );
    }

    return _buildFeaturedProductsHorizontalList();
  }

  Widget _buildShimmerLoadingState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final cardWidth = isTablet ? 200.0 : 160.0;
    final cardHeight = isTablet ? 260.0 : 220.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: 3, // Show 3 shimmer placeholders
            itemBuilder: (context, index) {
              return Container(
                width: cardWidth,
                margin: const EdgeInsets.only(right: 12.0),
                child: _buildProductCardShimmer(),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProductCardShimmer() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image shimmer
          Expanded(
            flex: 2,
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
            ),
          ),
          // Content shimmer
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Product name shimmer
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Price and stock shimmer
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 12,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 10,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProductsHorizontalList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final cardWidth = isTablet ? 200.0 : 160.0;
    final cardHeight = isTablet ? 260.0 : 220.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _featuredProducts.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Show loading indicator at the end when loading more
              if (index == _featuredProducts.length && _isLoadingMore) {
                return Container(
                  width: cardWidth,
                  alignment: Alignment.center,
                  child: _buildProductCardShimmer(),
                );
              }

              final product = _featuredProducts[index];
              return Container(
                width: cardWidth,
                margin: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () => widget.onProductTap(product),
                  child: UniversalProductCard(product: product),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}