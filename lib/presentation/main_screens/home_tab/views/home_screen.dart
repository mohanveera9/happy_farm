import 'package:happy_farm/presentation/main_screens/home_tab/widgets/shimmer_widget.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/featured_categorie_widget.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:happy_farm/presentation/auth/views/welcome_screen.dart';
import 'package:happy_farm/presentation/main_screens/cart/views/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/filter_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/filtered_products_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/productdetails_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/auto_scroll_banner_widget.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/all_products_widget.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/featured_products_widget.dart';
import 'package:happy_farm/presentation/main_screens/profile/widgets/custom_dialog.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';
import '../models/product_model.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/product_service.dart';

enum HomePageView { home, menu, filtered }

class HomeScreen extends StatefulWidget {
  final List<CategoryModel> categories;
  final String? userId;
  final int cartItemCount;
  final Future<void> Function()? onRefresh;
  final bool isLoading;
  final bool isCartCountLoading;
  final Future<void> Function()? onCartChanged;
  final Future<void> Function()? onNavigateToCart;
  final Future<void> Function(dynamic product)? onProductTap;

  const HomeScreen({
    Key? key,
    required this.categories,
    required this.userId,
    required this.cartItemCount,
    this.onRefresh,
    this.isLoading = false,
    this.isCartCountLoading = false,
    this.onCartChanged,
    this.onNavigateToCart,
    this.onProductTap, 

  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  HomePageView _currentPage = HomePageView.home;

  void _onMenuTap() {
    setState(() {
      _currentPage = HomePageView.menu;
    });
  }

  void _onCloseMenu() {
    setState(() {
      selectedCatId = '';
      _currentPage = HomePageView.home;
      _filteredProducts = [];
    });
  }

  void _showLoader() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => const Center(
        child: SizedBox(
          width: 80,
          height: 80,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(12),
              ),
            ),
            elevation: 6,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }

  void _hideLoader() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<FilterProducts> _filteredProducts = [];
  String selectedCatId = '';
  String selectedCatName = '';
  bool isSearch = false;
  final _productService = ProductService();
  bool isLoadingSearch = false;
  String filteredCategoryName = '';
  int? filteredminPrice;
  int? filteredmaxPrice;
  int? filteredrating;
  bool isCartCountLoading = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey<State<StatefulWidget>> _allProductsKey =
      GlobalKey<State<StatefulWidget>>();
  final GlobalKey<State<StatefulWidget>> _featuredProductsKey =
      GlobalKey<State<StatefulWidget>>();
  final GlobalKey<State<StatefulWidget>> _bannerKey =
      GlobalKey<State<StatefulWidget>>();

  // Removed _isHomeContentInitialized logic

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  
  Future<void> _navigateToCartScreen() async {
    if (widget.onNavigateToCart != null) {
      await widget.onNavigateToCart!();
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CartScreen(),
        ),
      );
    }
  }

  Future<void> _navigateToProductDetailsScreen(dynamic product) async {
    if (widget.onProductTap != null) {
      await widget.onProductTap!(product);
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetails(product: product),
        ),
      );
    }
  }

  Future<void> _fetchProductsByRating({
    required int rating,
    required String categoryId,
    required String categoryName,
  }) async {
    setState(() {});
    _showLoader();

    filteredCategoryName = categoryName;
    filteredrating = rating;

    try {
      final products = await _productService.getProductsByRating(
        catId: categoryId,
        rating: rating,
      );
      if (products.isNotEmpty) {
        setState(() {
          _filteredProducts = products;
          _currentPage = HomePageView.filtered;
        });
      } else {
        showErrorSnackbar(context, 'No filtered products found.');
      }
    } catch (e) {
      showErrorSnackbar(context, '$e');
    } finally {
      _hideLoader();
      setState(() {});
    }
  }

  Future<void> _fetchProductsByPrice({
    required int minPrice,
    required int maxPrice,
    required String categoryId,
    required String categoryName,
  }) async {
    setState(() {});
    _showLoader();

    filteredCategoryName = categoryName;
    filteredmaxPrice = maxPrice;
    filteredminPrice = minPrice;

    try {
      final products = await _productService.filterByPrice(
        catId: categoryId,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
      if (products.isNotEmpty) {
        setState(() {
          _filteredProducts = products;
          _currentPage = HomePageView.filtered;
        });
      } else {
        showErrorSnackbar(context, 'No filtered products found.');
      }
    } catch (e) {
      showErrorSnackbar(context, '$e');
    } finally {
      _hideLoader();
      setState(() {});
    }
  }

  Future<void> _fetchProductsByCategory(String catName) async {
    setState(() {});
    _showLoader();

    filteredCategoryName = catName;

    try {
      final products = await _productService.getProductsByCatName(catName);
      setState(() {
        _filteredProducts = products;
        _currentPage = HomePageView.filtered;
      });
    } catch (e) {
      debugPrint('Error fetching category products: $e');
    } finally {
      _hideLoader();
      setState(() {});
    }
  }

  Widget _buildHomeContent() {
    if (widget.isLoading) {
      return const ShimmerHomeScreen();
    } else {
      return RefreshIndicator(
        onRefresh: () async {
          if (widget.onRefresh != null) {
            await widget.onRefresh!();
          }
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildContentView(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => CustomConfirmDialog(
            title: "Are you sure?",
            message: "Do you really want to exit the app?",
            onYes: () {
              Navigator.of(context).pop(true);
            },
            onNo: () {
              Navigator.of(context).pop(false);
            },
            msg1: 'Cancel',
            msg2: 'Exit',
          ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop();
        }

        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  (_currentPage == HomePageView.menu ||
                          _currentPage == HomePageView.filtered)
                      ? Icons.close
                      : Icons.filter_list,
                  color: Colors.black87,
                ),
                onPressed: (_currentPage == HomePageView.menu ||
                        _currentPage == HomePageView.filtered)
                    ? _onCloseMenu
                    : _onMenuTap,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (builder) => WelcomeScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/sabba krish logo.png',
                      width: 140,
                      height: 70,
                    ),
                  ],
                ),
              ),
              // Updated cart icon with loading state
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.black87),
                    onPressed: _navigateToCartScreen,
                  ),
                  if (widget.isCartCountLoading)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: const SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (widget.cartItemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Text(
                          '${widget.cartItemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: IndexedStack(
            index: _currentPage.index,
            children: [
              _buildHomeContent(),
              FilterScreen(
                categories: widget.categories,
                onCategorySelected: (categoryId, categoryName) {
                  selectedCatId = categoryId;
                  selectedCatName = categoryName;
                },
                onPriceFilter: (minPrice, maxPrice) {
                  filteredminPrice = minPrice;
                  filteredmaxPrice = maxPrice;
                  filteredrating = null;
                  _fetchProductsByPrice(
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                    categoryId: selectedCatId,
                    categoryName: selectedCatName,
                  );
                },
                onRatingFilter: (rating) {
                  filteredrating = rating;
                  filteredminPrice = null;
                  filteredmaxPrice = null;
                  _fetchProductsByRating(
                    rating: rating,
                    categoryId: selectedCatId,
                    categoryName: selectedCatName,
                  );
                },
                onApplyFilters: () {
                  if (selectedCatId.isNotEmpty) {
                    filteredminPrice = null;
                    filteredmaxPrice = null;
                    filteredrating = null;
                    _fetchProductsByCategory(selectedCatName);
                  }
                },
                onClose: _onCloseMenu,
              ),
              FilteredProductsScreen(
                products: _filteredProducts,
                categoryName: filteredCategoryName,
                minPrice: filteredminPrice,
                maxPrice: filteredmaxPrice,
                rating: filteredrating,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoScrollBannerWidget(
          key: _bannerKey,
          height: 180.0,
          autoScrollDuration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16.0),
          borderRadius: BorderRadius.circular(12.0),
          onBannerTap: () {},
        ),
        _buildSectionTitle('Featured Categories'),
        FeaturedCategoriesWidget(
          onCategorySelected: (categoryName) {
            _fetchProductsByCategory(categoryName);
          },
        ),
        _buildSectionTitle('Featured Products'),
        FeaturedProductsWidget(
          key: _featuredProductsKey,
          onProductTap: _navigateToProductDetailsScreen,
          parentScrollController: _scrollController,
          initialVisibleCount: 4,
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('All Products'),
        AllProductsWidget(
          key: _allProductsKey,
          onProductTap: _navigateToProductDetailsScreen,
          parentScrollController: _scrollController,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}