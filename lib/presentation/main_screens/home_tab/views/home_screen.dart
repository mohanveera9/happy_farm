import 'package:happy_farm/presentation/main_screens/home_tab/widgets/category_drawer.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/home_content.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:happy_farm/presentation/auth/views/welcome_screen.dart';
import 'package:happy_farm/presentation/main_screens/cart/views/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/filter_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/filtered_products_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/productdetails_screen.dart';
import 'package:happy_farm/presentation/main_screens/profile/widgets/custom_dialog.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';
import '../models/product_model.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/product_service.dart';

enum HomePageView { home, filtered, filter }

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Filter related variables
  List<FilterProducts> _filteredProducts = [];
  String selectedCatId = '';
  String selectedCatName = '';
  String filteredCategoryName = '';
  int? filteredminPrice;
  int? filteredmaxPrice;
  int? filteredrating;
  int? _currentFilterRating;

  // Service and loading states
  final _productService = ProductService();
  bool isLoadingSearch = false;

  // Controllers
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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Navigation methods
  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _onFilterTap() {
    setState(() {
      _currentPage = HomePageView.filter;
    });
  }

  void _onCloseFilter() {
    setState(() {
      selectedCatId = '';
      selectedCatName = '';
      filteredCategoryName = '';
      filteredminPrice = null;
      filteredmaxPrice = null;
      filteredrating = null;
      _filteredProducts = [];
      _currentPage = HomePageView.home;
    });
  }

  // Loader methods
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
              borderRadius: BorderRadius.all(Radius.circular(12)),
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

  // Navigation to screens
  Future<void> _navigateToCartScreen() async {
    if (widget.onNavigateToCart != null) {
      await widget.onNavigateToCart!();
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CartScreen()),
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
            builder: (context) => ProductDetails(product: product)),
      );
    }
  }

  // Filter methods
  Future<void> _fetchProductsByRating({
    required int rating,
    required String categoryId,
    required String categoryName,
  }) async {
    _showLoader();

    try {
      final products = await _productService.getProductsByRating(
        catId: categoryId,
        rating: rating,
      );

      if (products.isNotEmpty) {
        setState(() {
          filteredCategoryName = categoryName;
          filteredrating = rating;
          _currentFilterRating = rating;
          filteredminPrice = null;
          filteredmaxPrice = null;
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
    }
  }

  Future<void> _fetchProductsByPrice({
    required int minPrice,
    required int maxPrice,
    required String categoryId,
    required String categoryName,
  }) async {
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
    }
  }

  Future<void> _fetchProductsByCategory(String catName) async {
    _showLoader();
    filteredCategoryName = catName;

    try {
      final products = await _productService.getProductsByCatName(catName);
      setState(() {
        _filteredProducts = products;
        _currentPage = HomePageView.filtered;
      });
      // Close drawer after selection
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error fetching category products: $e');
    } finally {
      _hideLoader();
    }
  }

  Future<void> _fetchProductsBySubCategory(
      String subCatId, String subCatName) async {
    _showLoader();
    filteredCategoryName = subCatName;

    try {
      final products = await _productService.getProductsBySubCateId(subCatId);
      setState(() {
        _filteredProducts = products;
        _currentPage = HomePageView.filtered;
      });
      // Close drawer after selection
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error fetching subcategory products: $e');
      showErrorSnackbar(context, 'Failed to load subcategory products: $e');
    } finally {
      _hideLoader();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return WillPopScope(
      onWillPop: () async {
        if (_currentPage != HomePageView.home) {
          _onCloseFilter();
          return false;
        }

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => CustomConfirmDialog(
            title: "Are you sure?",
            message: "Do you really want to exit the app?",
            onYes: () => Navigator.of(context).pop(true),
            onNo: () => Navigator.of(context).pop(false),
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
        appBar: _buildAppBar(),
        drawer: CategoryDrawer(
          categories: widget.categories,
          onCategorySelected: _fetchProductsByCategory,
          onSubCategorySelected: _fetchProductsBySubCategory, 
          onFilterTap: _onFilterTap,
        ),
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: IndexedStack(
            index: _currentPage.index,
            children: [
              HomeContent(
                isLoading: widget.isLoading,
                onRefresh: widget.onRefresh,
                scrollController: _scrollController,
                bannerKey: _bannerKey,
                featuredProductsKey: _featuredProductsKey,
                allProductsKey: _allProductsKey,
                onProductTap: _navigateToProductDetailsScreen,
                onCategorySelected: _fetchProductsByCategory,
              ),
              FilteredProductsScreen(
                products: _filteredProducts,
                categoryName: filteredCategoryName,
                minPrice: filteredminPrice,
                maxPrice: filteredmaxPrice,
                rating: _currentFilterRating ?? filteredrating,
              ),
              FilterScreen(
                categories: widget.categories,
                onCategorySelected: (categoryId, categoryName) {
                  setState(() {
                    selectedCatId = categoryId;
                    selectedCatName = categoryName;
                    filteredCategoryName = categoryName;
                  });
                },
                onPriceFilter: (minPrice, maxPrice) {
                  setState(() {
                    filteredminPrice = minPrice;
                    filteredmaxPrice = maxPrice;
                    filteredrating = null;
                    filteredCategoryName = selectedCatName;
                  });
                  _fetchProductsByPrice(
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                    categoryId: selectedCatId,
                    categoryName: selectedCatName,
                  );
                },
                onRatingFilter: (rating) {
                  setState(() {
                    filteredrating = rating;
                    filteredminPrice = null;
                    filteredmaxPrice = null;
                    filteredCategoryName = selectedCatName;
                  });
                  _fetchProductsByRating(
                    rating: rating,
                    categoryId: selectedCatId,
                    categoryName: selectedCatName,
                  );
                },
                onApplyFilters: () {
                  if (selectedCatId.isNotEmpty) {
                    setState(() {
                      filteredrating = null;
                      filteredCategoryName = selectedCatName;
                    });
                    _fetchProductsByCategory(selectedCatName);
                  }
                },
                onClose: _onCloseFilter,
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              (_currentPage == HomePageView.filtered ||
                      _currentPage == HomePageView.filter)
                  ? Icons.close
                  : Icons.menu,
              color: Colors.black87,
            ),
            onPressed: (_currentPage == HomePageView.filtered ||
                    _currentPage == HomePageView.filter)
                ? _onCloseFilter
                : _openDrawer,
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (builder) => WelcomeScreen()),
              );
            },
            child: Image.asset(
              'assets/images/sabba krish logo.png',
              width: 140,
              height: 70,
            ),
          ),
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
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }
}