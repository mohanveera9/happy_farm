import 'package:flutter/material.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:happy_farm/presentation/main_screens/cart/services/cart_service.dart';
import 'package:happy_farm/presentation/main_screens/cart/views/cart_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/product_model.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/category_service.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/home_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/productdetails_screen.dart';
import 'package:happy_farm/presentation/main_screens/orders/views/order_screen.dart';
import 'package:happy_farm/presentation/main_screens/profile/views/profile_screen.dart';
import 'package:happy_farm/presentation/main_screens/search/views/search_screen.dart';
import 'package:happy_farm/presentation/main_screens/wishlist/views/wishlist_screen.dart';
import 'package:happy_farm/presentation/auth/services/user_service.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  final int selectedIndex;
  const MainScreen({Key? key, this.selectedIndex = 0}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isHomeDataLoading = true;
  List<CategoryModel> _categories = [];
  String? _userId;
  int _cartItemCount = 0;
  bool _isCartCountLoading = false;
  bool _categoriesFetched = false; // Track if categories are already fetched

  Future<void> _fetchHomeData() async {
    setState(() {
      _isHomeDataLoading = true;
    });
    try {
      // Only fetch categories if not already fetched
      if (!_categoriesFetched) {
        final categories = await CategoryService.fetchCategories();
        setState(() {
          _categories = categories;
          _categoriesFetched = true;
        });
      }
      
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      setState(() {
        _userId = userId;
      });
      await _fetchCartCount();
    } catch (e) {
      debugPrint('Error fetching home data: $e');
    } finally {
      setState(() {
        _isHomeDataLoading = false;
      });
    }
  }

  // Method to refresh other data without refetching categories
  Future<void> _refreshHomeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      setState(() {
        _userId = userId;
      });
      await _fetchCartCount();
    } catch (e) {
      debugPrint('Error refreshing home data: $e');
    }
  }

  Future<void> _fetchCartCount() async {
    setState(() {
      _isCartCountLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      int cartCount = 0;
      if (userId != null) {
        final cartItems = await CartService.fetchCart();
        cartCount = cartItems.length;
      }
      setState(() {
        _cartItemCount = cartCount;
      });
    } catch (e) {
      debugPrint('Error fetching cart count: $e');
    } finally {
      setState(() {
        _isCartCountLoading = false;
      });
    }
  }

  late int _selectedIndex;
  bool _isCheckingLogin = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _checkLoginStatus();
    _fetchHomeData();
  }

  Future<void> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      final userData = await UserService().fetchUserDetails(userId);

      if (userData != null) {
        Provider.of<UserProvider>(context, listen: false).setUser(
          username: userData['name'] ?? 'No Name',
          email: userData['email'] ?? 'No Email',
          phoneNumber: userData['phone'] ?? 'No Phone',
          image: userData['image'] ?? 'No image'
        );
      }
    }
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userId = prefs.getString('userId');

    setState(() {
      _isLoggedIn = token != null && userId != null;
      _isCheckingLogin = false;
    });
    if (_isLoggedIn) {
      await getUser();
    }
  }

  final GlobalKey<WishlistScreenState> _wishlistKey =
      GlobalKey<WishlistScreenState>();
  final GlobalKey<OrdersScreenState> _ordersKey =
      GlobalKey<OrdersScreenState>();

  void _onItemTapped(int index) {
    // If switching to wishlist tab (index 2), refresh the data
    if (index == 2 && _selectedIndex != 2) {
      // Small delay to ensure the screen is built
      Future.delayed(Duration(milliseconds: 0), () {
        _wishlistKey.currentState?.refreshWishlist();
      });
    }

    // If switching to orders tab (index 3), refresh the data
    if (index == 3 && _selectedIndex != 3) {
      // Small delay to ensure the screen is built
      Future.delayed(Duration(milliseconds: 0), () {
        _ordersKey.currentState?.refreshOrders();
      });
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _navigateToCartScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(),
      ),
    );

    if (result == 'cart_updated') {
      await _fetchCartCount();
    }
  }

  Future<void> _naviagateToProductDetailsScreen(dynamic product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetails(
          product: product,
        ),
      ),
    );

    if (result == 'cart_updated') {
      await _fetchCartCount();
    }
  }

  List<Widget> get _screens {
    return [
      HomeScreen(
        categories: _categories,
        userId: _userId,
        cartItemCount: _cartItemCount,
        isCartCountLoading: _isCartCountLoading,
        onRefresh: _refreshHomeData, // Use refresh method that doesn't refetch categories
        isLoading: _isHomeDataLoading,
        onCartChanged: _fetchCartCount,
        onNavigateToCart: _navigateToCartScreen,
        onProductTap: _naviagateToProductDetailsScreen,
      ),
      const SearchScreen(),
      WishlistScreen(key: _wishlistKey),
      OrdersScreen(key: _ordersKey),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLogin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 56, 142, 60),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            currentIndex: _selectedIndex,
            onTap: _isHomeDataLoading ? null : _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                activeIcon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                activeIcon: Icon(Icons.favorite),
                label: 'Wishlist',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}