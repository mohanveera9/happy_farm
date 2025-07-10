import 'dart:async';
import 'package:flutter/services.dart';
import 'package:happy_farm/presentation/auth/views/welcome_screen.dart';
import 'package:happy_farm/presentation/main_screens/cart/models/cart_model.dart';
import 'package:happy_farm/presentation/main_screens/cart/views/cart_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/banner_service.dart';
import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/filter_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/filtered_products_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/productdetails_screen.dart';
import 'package:happy_farm/presentation/main_screens/cart/services/cart_service.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/shimmer_widget.dart';
import 'package:happy_farm/presentation/main_screens/profile/widgets/custom_dialog.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';
import '../models/banner_model.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/category_service.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/product_service.dart';

enum HomePageView { home, menu, filtered }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
  List<FeaturedProduct> _featuredProducts = [];
  List<AllProduct> _allProducts = [];
  List<CategoryModel> _categories = [];
  List<FilterProducts> _filteredProducts = [];
  int _visibleFeaturedCount = 2;
  int _visibleAllCount = 2;
  String selectedCatId = '';
  String selectedCatName = '';
  bool isSearch = false;
  final _productService = ProductService();
  bool isLoadingSearch = false;
  String? userId;
  int cartItemCount = 0;
  String filteredCategoryName = '';
  int filteredminPrice = 0;
  int filteredmaxPrice = 60000;
  int filteredrating = 0;

  @override
  void initState() {
    super.initState();
    fetchAllProducts();
    fetchFeaturedProducts();
    fetchCategories();
    _loadUser();
    loadCartItemCount();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  Future<void> loadCartItemCount() async {
    try {
      final List<CartItem> cartItems = await CartService.fetchCart();
      setState(() {
        cartItemCount = cartItems.length;
      });
    } catch (e) {
      print("Error fetching cart item count: $e");
      setState(() {
        cartItemCount = 0;
      });
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

  Future<void> fetchFeaturedProducts() async {
    try {
      final products = await _productService.getFeaturedProducts();
      setState(() {
        _featuredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
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

  Future<void> fetchAllProducts() async {
    try {
      final products = await _productService.getProducts();
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching all products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartScreen(),
                        ),
                      );
                    },
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
                        child: Text(
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
    switch (_currentPage) {
      case HomePageView.menu:
        return FilterScreen(
          categories: _categories,
          onCategorySelected: (categoryId, categoryName) {
            selectedCatId = categoryId;
            selectedCatName = categoryName;
          },
          onPriceFilter: (minPrice, maxPrice) {
            _fetchProductsByPrice(
              minPrice: minPrice,
              maxPrice: maxPrice,
              categoryId: selectedCatId,
              categoryName: selectedCatName,
            );
          },
          onRatingFilter: (rating) {
            _fetchProductsByRating(
              rating: rating,
              categoryId: selectedCatId,
              categoryName: selectedCatName,
            );
          },
          onApplyFilters: () {
            if (selectedCatId.isNotEmpty) {
              _fetchProductsByCategory(selectedCatName);
            }
          },
          onClose: _onCloseMenu,
        );
      case HomePageView.home:
        return _isLoading
            ? _buildLoadingView()
            : SingleChildScrollView(
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
    return Stack(
      children: [
        // Main scrollable content (banners, featured, all)
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AutoScrollBanner(),
              _buildSectionTitle('Featured Categories'),
              _buildCategorySection(),
              _buildSectionTitle('Featured Products'),
              _buildFeaturedProducts(),
              SizedBox(
                height: 20,
              ),
              _buildSectionTitle('All Products'),
              _buildAllProducts(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    if (_categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
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
                    const SizedBox(height: 5),
                    Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
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

  Widget _buildFeaturedProducts() {
    if (_featuredProducts.isEmpty) {
      return const Center(child: Text('No featured products available.'));
    }

    final visibleProducts =
        _featuredProducts.reversed.take(_visibleFeaturedCount).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? 3 : 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 0.75, // Fixed optimal ratio
            ),
            itemCount: visibleProducts.length,
            itemBuilder: (context, index) {
              final product = visibleProducts[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetails(product: product),
                    ),
                  );
                },
                child: UniversalProductCard(product: product),
              );
            },
          ),
          if (_visibleFeaturedCount < _featuredProducts.length)
            TextButton(
              onPressed: () {
                setState(() {
                  _visibleFeaturedCount += 5;
                  if (_visibleFeaturedCount > _featuredProducts.length) {
                    _visibleFeaturedCount = _featuredProducts.length;
                  }
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 1, 140, 255),
              ),
              child: const Text('View All'),
            ),
        ],
      ),
    );
  }

  Widget _buildAllProducts() {
    if (_allProducts.isEmpty) {
      return const Center(child: Text('No products available.'));
    }

    final visibleProducts =
        _allProducts.reversed.take(_visibleAllCount).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? 3 : 2;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // Keep aspect ratio consistent
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.75, // Fixed optimal ratio
                  ),
                  itemCount: visibleProducts.length,
                  itemBuilder: (context, index) {
                    final product = visibleProducts[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetails(product: product),
                          ),
                        );
                      },
                      child: UniversalProductCard(product: product),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            if (_visibleAllCount < _allProducts.length)
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _visibleAllCount += 5;
                      if (_visibleAllCount > _allProducts.length) {
                        _visibleAllCount = _allProducts.length;
                      }
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color.fromARGB(255, 1, 140, 255),
                  ),
                  child: const Text('View All'),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.displaySmall,
      ),
    );
  }
}

class AutoScrollBanner extends StatefulWidget {
  const AutoScrollBanner({Key? key}) : super(key: key);

  @override
  _AutoScrollBannerState createState() => _AutoScrollBannerState();
}

class _AutoScrollBannerState extends State<AutoScrollBanner> {
  List<BannerModel> _banners = [];
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;
  final _bannerService = BannerService();

  @override
  void initState() {
    super.initState();
    fetchBanners();
  }

  Future<void> fetchBanners() async {
    setState(() {});

    try {
      final banners = await _bannerService.fetchMainBanners();
      if (!mounted) return;
      setState(() {
        _banners = banners;
      });
      _startAutoScroll();
    } catch (e) {
      print('Error fetching banners: $e');
      if (!mounted) return;
      setState(() {});
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_banners.isEmpty) return;

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

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180.0,
      child: _banners.isEmpty
          ? const Center(child: Text('No banners available'))
          : PageView.builder(
              controller: _pageController,
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    image: DecorationImage(
                      image: NetworkImage(_banners[index].images.first),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: const Align(
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
