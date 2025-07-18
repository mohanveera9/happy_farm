// Updated HomeScreen with AutomaticKeepAliveClientMixin to persist data
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:happy_farm/presentation/auth/views/welcome_screen.dart';
import 'package:happy_farm/presentation/main_screens/cart/models/cart_model.dart';
import 'package:happy_farm/presentation/main_screens/cart/views/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/filter_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/filtered_products_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/productdetails_screen.dart';
import 'package:happy_farm/presentation/main_screens/cart/services/cart_service.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/auto_scroll_banner_widget.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/shimmer_widget.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/all_products_widget.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/featured_products_widget.dart';
import 'package:happy_farm/presentation/main_screens/profile/widgets/custom_dialog.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../models/banner_model.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/category_service.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/product_service.dart';

enum HomePageView { home, menu, filtered }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // This keeps the state alive

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
  bool _isLoading = true;
  List<CategoryModel> _categories = [];
  List<FilterProducts> _filteredProducts = [];
  String selectedCatId = '';
  String selectedCatName = '';
  bool isSearch = false;
  final _productService = ProductService();
  bool isLoadingSearch = false;
  String? userId;
  int cartItemCount = 0;
  String filteredCategoryName = '';
  int? filteredminPrice;
  int? filteredmaxPrice;
  int? filteredrating;
  bool isCartCountLoading = false;

  // Flag to track if data has been loaded initially
  bool _hasInitialDataLoaded = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey<State<StatefulWidget>> _allProductsKey =
      GlobalKey<State<StatefulWidget>>();
  final GlobalKey<State<StatefulWidget>> _featuredProductsKey =
      GlobalKey<State<StatefulWidget>>();
  final GlobalKey<State<StatefulWidget>> _bannerKey =
      GlobalKey<State<StatefulWidget>>();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Initialize data only once
  Future<void> _initializeData() async {
    if (!_hasInitialDataLoaded) {
      await fetchCategories();
      await _loadUser();
      await loadCartItemCount();
      
      setState(() {
        _hasInitialDataLoaded = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  // Load cart count (only called initially and when returning from cart)
  Future<void> loadCartItemCount() async {
    try {
      setState(() {
        isCartCountLoading = true;
      });

      final List<CartItem> cartItems = await CartService.fetchCart();

      setState(() {
        isCartCountLoading = false;
        cartItemCount = cartItems.length;
      });
    } catch (e) {
      print("Error fetching cart item count: $e");
      setState(() {
        isCartCountLoading = false;
        cartItemCount = 0;
      });
    }
  }

  // Method to refresh only cart count (can be called when user returns to home)
  Future<void> refreshCartCount() async {
    await loadCartItemCount();
  }

  // Navigate to cart screen and handle return
  Future<void> _navigateToCartScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(),
      ),
    );

    // Only refresh cart count if cart was modified
    if (result == 'cart_updated' || result == true) {
      loadCartItemCount();
    }
  }

  // Navigate to product details screen and handle return
  Future<void> _navigateToProductDetailsScreen(dynamic product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetails(product: product),
      ),
    );

    // Only refresh cart count if cart was modified
    if (result == 'cart_updated_int_product_details' || result == true) {
      loadCartItemCount();
    }
  }

  Future<void> fetchCategories() async {
    try {
      final categories = await CategoryService.fetchCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _fetchProductsByRating({
    required int rating,
    required String categoryId,
    required String categoryName,
  }) async {
    setState(() {
      _isLoading = true;
    });
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchProductsByPrice({
    required int minPrice,
    required int maxPrice,
    required String categoryId,
    required String categoryName,
  }) async {
    setState(() {
      _isLoading = true;
    });
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchProductsByCategory(String catName) async {
    setState(() {
      _isLoading = true;
    });
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
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
              // Left: Menu or Close
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

              // Center: Icon + Text
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

              // Right: Cart Icon with badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.black87),
                    onPressed: _navigateToCartScreen,
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: isCartCountLoading
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                '$cartItemCount',
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
          child: _buildBodyContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const ShimmerHomeScreen();
  }

  Widget _buildBodyContent() {
    // Show loading only if data hasn't been loaded initially
    if (!_hasInitialDataLoaded) {
      return _buildLoadingView();
    }

    switch (_currentPage) {
      case HomePageView.menu:
        return FilterScreen(
          categories: _categories,
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
        );
      case HomePageView.home:
        return SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildContentView(),
        );
      case HomePageView.filtered:
        return FilteredProductsScreen(
          products: _filteredProducts,
          categoryName: filteredCategoryName,
          minPrice: filteredminPrice,
          maxPrice: filteredmaxPrice,
          rating: filteredrating,
        );
    }
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
          onBannerTap: () {
            // Handle banner tap - navigate to specific screen or show details
            print('Banner tapped');
          },
        ),
        _buildSectionTitle('Featured Categories'),
        _buildCategorySection(),
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
        const SizedBox(height: 20), // Add some bottom padding
      ],
    );
  }

  Widget _buildCategorySection() {
    if (_categories.isEmpty) {
      return Container(
        height: 120,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return GestureDetector(
              onTap: () {
                _fetchProductsByCategory(category.name);
              },
              child: Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Color(int.parse(
                            category.color.replaceFirst('#', '0xff'))),
                        shape: BoxShape.circle,
                        border:
                            Border.all(width: 0, color: Colors.grey.shade300),
                        image: DecorationImage(
                          image: NetworkImage(category.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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