import 'package:flutter/material.dart';
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
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

        // Loading indicator for pagination
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),

        // Show pagination info and load more button
        if (_hasMoreProducts && !_isLoadingMore && !_isLastPage)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Showing ${_allProducts.length} of $_totalProducts products',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadMoreProducts,
                  child: Text(
                      'Load More (Page ${_currentPage + 1} of $_totalPages)'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
