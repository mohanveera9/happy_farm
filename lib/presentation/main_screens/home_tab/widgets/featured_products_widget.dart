import 'package:flutter/material.dart';
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
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

  Widget _buildFeaturedProductsHorizontalList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final cardWidth = isTablet ? 200.0 : 160.0;
    final cardHeight = isTablet ? 260.0 : 220.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 10,
        ),
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
                  child: const CircularProgressIndicator(),
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
