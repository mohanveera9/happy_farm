import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/product_model.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/product_service.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/product_card.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';

class AllProductsWidget extends StatefulWidget {
  final Function(dynamic product) onProductTap;
  final ScrollController? parentScrollController;

  const AllProductsWidget({
    Key? key,
    required this.onProductTap,
    this.parentScrollController,
  }) : super(key: key);

  @override
  State<AllProductsWidget> createState() => _AllProductsWidgetState();
}

class _AllProductsWidgetState extends State<AllProductsWidget> {
  final ProductService _productService = ProductService();

  List<AllProduct> _allProducts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;
  int _currentPage = 1;
  final int _perPage = 10;
  int _totalPages = 0;
  int _totalProducts = 0;
  bool _isLastPage = false;

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.parentScrollController ?? ScrollController();
    _setupScrollListener();
    _fetchAllProducts();
  }

  @override
  void dispose() {
    if (widget.parentScrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // Trigger earlier
        if (!_isLoadingMore && _hasMoreProducts && !_isLastPage) {
          _loadMoreProducts();
        }
      }
    });
  }

  Future<void> _fetchAllProducts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Use the correct method name from ProductService
      final response = await _productService.getProductsWithPagination(
        page: _currentPage,
        perPage: _perPage,
      );

      print("Initial fetch response: $response"); // Debug print

      setState(() {
        _allProducts = response['products'] ?? [];
        _totalPages = response['totalPages'] ?? 0;
        _totalProducts = response['totalProducts'] ?? 0;
        _isLoading = false;
        _hasMoreProducts = _currentPage < _totalPages;
        _isLastPage = _currentPage >= _totalPages;
      });

      // Pre-cache product images for better performance
      _preCacheProductImages();

      print(
          "After initial fetch - Products: ${_allProducts.length}, Total Pages: $_totalPages, Current Page: $_currentPage"); // Debug print
    } catch (e) {
      print('Error fetching all products: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showErrorSnackbar(context, 'Failed to load products');
      }
    }
  }

  // Pre-cache product images to improve performance
  void _preCacheProductImages() {
    for (final product in _allProducts) {
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
          "Load more blocked: Loading: $_isLoadingMore, Has more: $_hasMoreProducts, Is last: $_isLastPage");
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;

      print("Loading page $nextPage of $_totalPages"); // Debug print

      // Check if we're about to exceed total pages
      if (nextPage > _totalPages) {
        setState(() {
          _hasMoreProducts = false;
          _isLastPage = true;
        });
        return;
      }

      // Use the correct method name from ProductService
      final response = await _productService.getProductsWithPagination(
        page: nextPage,
        perPage: _perPage,
      );

      print("Load more response: $response"); // Debug print

      final newProducts = response['products'] ?? [];

      setState(() {
        if (newProducts.isNotEmpty) {
          _allProducts.addAll(newProducts);
          _currentPage = nextPage;
          print(
              "Added ${newProducts.length} products. Total now: ${_allProducts.length}"); // Debug print
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
      print('Error loading more products: $e');
      if (mounted) {
        showErrorSnackbar(context, 'Failed to load more products');
      }
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> refreshProducts() async {
    setState(() {
      _allProducts = [];
      _currentPage = 1;
      _hasMoreProducts = true;
      _isLoadingMore = false;
      _totalPages = 0;
      _totalProducts = 0;
      _isLastPage = false;
    });
    await _fetchAllProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmerLoadingState();
    }

    if (_allProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No products available.'),
        ),
      );
    }

    return _buildProductsGrid();
  }

  Widget _buildShimmerLoadingState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? 3 : 2;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: 6, // Show 6 shimmer placeholders
            itemBuilder: (context, index) {
              return _buildProductCardShimmer();
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

  Widget _buildProductsGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? 3 : 2;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: _allProducts.length,
            itemBuilder: (context, index) {
              final product = _allProducts[index];
              return GestureDetector(
                onTap: () => widget.onProductTap(product),
                child: UniversalProductCard(product: product),
              );
            },
          ),
        ),
        if (_isLoadingMore)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Show additional shimmer cards when loading more
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: 2,
                    itemBuilder: (context, index) {
                      return _buildProductCardShimmer();
                    },
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
