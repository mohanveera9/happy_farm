import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/product_model.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/productdetails_screen.dart';
import 'package:happy_farm/presentation/main_screens/cart/services/cart_service.dart'
    show CartService;
import 'package:happy_farm/presentation/main_screens/wishlist/services/whislist_service.dart';
import 'package:happy_farm/presentation/main_screens/wishlist/widgets/wishListShimmer.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';
import 'package:happy_farm/widgets/without_login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => WishlistScreenState();
}

class WishlistScreenState extends State<WishlistScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // Keep the screen alive to prevent unnecessary rebuilds
  @override
  bool get wantKeepAlive => true;

  late AnimationController _controller;
  List<Map<String, dynamic>> wishlist = [];
  bool _isLoggedIn = false;
  bool _isAddingAllToCart = false;
  Set<String> _removingProductIds = {};

  // Pagination variables
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _hasNextPage = false;
  bool _hasPrevPage = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  final int _perPage = 5;

  // Track if data has been loaded initially
  bool _hasInitiallyLoaded = false;

  // Track if we need to refresh data
  bool _needsRefresh = false;

  final ScrollController _scrollController = ScrollController();

  // Enhanced color scheme
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color veryLightGreen = Color(0xFFE8F5E8);
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textMedium = Color(0xFF546E7A);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scrollController.addListener(_onScroll);
    _initializeScreen();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_hasNextPage && !_isLoadingMore) {
        _loadMoreWishlist();
      }
    }
  }

  Future<void> _initializeScreen() async {
    await _checkLoginStatus();
    if (_isLoggedIn && !_hasInitiallyLoaded) {
      await _loadWishlist(page: 1, isRefresh: true);
      _hasInitiallyLoaded = true;
    }
  }

  // Method to be called from outside when wishlist changes
  void markForRefresh() {
    setState(() {
      _needsRefresh = true;
    });
  }

  // Method to refresh only when actually needed
  Future<void> _refreshIfNeeded() async {
    if (_needsRefresh && _isLoggedIn) {
      await _loadWishlist(page: 1, isRefresh: true);
      _needsRefresh = false;
    }
  }

  Future<void> _loadWishlist(
      {required int page, bool isRefresh = false}) async {
    if (!_isLoggedIn) return;

    setState(() {
      if (isRefresh) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final response = await WishlistService.fetchWishlistWithPagination(
        page: page,
        perPage: _perPage,
      );

      final items = response['items'] ?? [];

      setState(() {
        if (isRefresh) {
          wishlist = List<Map<String, dynamic>>.from(items);
        } else {
          wishlist.addAll(List<Map<String, dynamic>>.from(items));
        }

        _currentPage = response['currentPage'] ?? 1;
        _totalPages = response['totalPages'] ?? 1;
        _totalItems = response['totalItems'] ?? 0;
        _hasNextPage = response['hasNextPage'] ?? false;
        _hasPrevPage = response['hasPrevPage'] ?? false;

        _isLoading = false;
        _isLoadingMore = false;
      });

      if (isRefresh) {
        _controller.forward();
      }
    } catch (e) {
      print('❌ Error loading wishlist: $e'); // Debug log
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });

      if (mounted) {
        showErrorSnackbar(context, 'Error loading wishlist: $e');
      }
    }
  }

  Future<void> _loadMoreWishlist() async {
    if (_hasNextPage && !_isLoadingMore) {
      await _loadWishlist(page: _currentPage + 1);
    }
  }

  Future<void> _refreshWishlist() async {
    await _loadWishlist(page: 1, isRefresh: true);
  }

  // Public method to refresh wishlist from external widgets
  Future<void> refreshWishlist() async {
    await _refreshWishlist();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we need to refresh when screen becomes visible
    if (_hasInitiallyLoaded) {
      _refreshIfNeeded();
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');

    setState(() {
      _isLoggedIn = token != null && userId != null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        title: const Text('My Wishlist'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_totalItems items',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    if (!_isLoggedIn) {
      return WithoutLoginScreen(
        icon: Icons.favorite_border_outlined,
        title: 'Wishlist',
        subText:
            'Login to add products to your wishlist and manage your orders',
      );
    }

    if (_isLoading) {
      return const Center(child: WishlistShimmer());
    }

    if (wishlist.isEmpty && _hasInitiallyLoaded) {
      return _buildEmptyWishlist();
    }

    return RefreshIndicator(
      onRefresh: _refreshWishlist,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: wishlist.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == wishlist.length) {
            return _buildLoadingIndicator();
          }

          return _buildWishlistItem(index);
        },
      ),
    );
  }

  Widget _buildEmptyWishlist() {
    return RefreshIndicator(
      onRefresh: _refreshWishlist,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: veryLightGreen,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: 60,
                    color: accentGreen,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Your wishlist is empty",
                  style: TextStyle(
                    fontSize: 20,
                    color: textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Start adding your favorite products",
                  style: TextStyle(
                    fontSize: 16,
                    color: textMedium,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Pull down to refresh",
                  style: TextStyle(
                    fontSize: 14,
                    color: textMedium.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: List.generate(2, (index) => _buildShimmerCartItem()),
    );
  }

  Widget _buildShimmerCartItem() {
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Row(
            children: [
              // Image shimmer
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              // Content shimmer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name shimmer
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price shimmer
                    Container(
                      height: 14,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtotal shimmer
                    Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistItem(int index) {
    final item = wishlist[index];
    final product = item['productId'];

    final title = product['name'] ?? 'Unknown Product';
    final rating = product['rating'] ?? 0.0;
    final image = (product['images'] != null && product['images'].isNotEmpty)
        ? product['images'][0]
        : null;
    final prices = product['prices'];
    final stock = prices != null && prices is List && prices.isNotEmpty
        ? (prices[0]['countInStock'] ?? 0)
        : 0;
    final priceObj = (prices != null && prices.isNotEmpty) ? prices[0] : null;
    final priceValue = priceObj != null ? priceObj['actualPrice'] : 0.0;

    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          (1 / wishlist.length) * index,
          1.0,
          curve: Curves.fastOutSlowIn,
        ),
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: GestureDetector(
        onTap: () async {
          final productInstance = AllProduct.fromJson(product);
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (builder) => ProductDetails(
                product: productInstance,
              ),
            ),
          );

          // Check if wishlist was modified in product details
          if (result == 'wishlist_updated') {
            markForRefresh();
            _refreshIfNeeded();
          }
        },
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: image != null
                      ? CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.error,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildRemoveButton(product, index),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${priceValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < rating.floor()
                                  ? Icons.star
                                  : i < rating
                                      ? Icons.star_half
                                      : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stock > 0 ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: stock > 0 ? Colors.green[800] : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveButton(Map<String, dynamic> product, int index) {
    final productId = product['_id'];
    final isRemoving = _removingProductIds.contains(productId);

    return isRemoving
        ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.red,
            ),
          )
        : InkWell(
            onTap: () => _removeFromWishlist(productId, index),
            child: Icon(Icons.favorite, color: Colors.red[400]),
          );
  }

  Future<void> _removeFromWishlist(String productId, int index) async {
    if (_removingProductIds.contains(productId)) return;

    setState(() => _removingProductIds.add(productId));

    try {
      final msg = await WishlistService.removeFromWishlist(productId);

      if (mounted) {
        setState(() {
          wishlist.removeAt(index);
          _removingProductIds.remove(productId);
          _totalItems = _totalItems - 1;
        });
        showSuccessSnackbar(context, msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _removingProductIds.remove(productId);
        });
        showErrorSnackbar(context, '$e');
      }
    }
  }

  Widget? _buildFloatingActionButton() {
    if (!_isLoggedIn || wishlist.isEmpty) return null;

    return FloatingActionButton.extended(
      onPressed: _isAddingAllToCart ? null : _addAllToCart,
      backgroundColor: _isAddingAllToCart ? Colors.grey : Colors.green[800],
      icon: _isAddingAllToCart
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.shopping_cart),
      label: Text(_isAddingAllToCart ? 'Adding...' : 'Add All to Cart'),
    );
  }

  Future<void> _addAllToCart() async {
    setState(() => _isAddingAllToCart = true);

    bool allSuccess = true;
    bool anyFailure = false;

    for (var item in wishlist) {
      final product = item['productId'];
      final prices = product['prices'];

      if (prices != null && prices.isNotEmpty) {
        final priceObj = prices[0];
        final productId = product['_id'];
        final priceId = priceObj['_id'];

        try {
          final result = await CartService.addToCart(
            productId: productId,
            priceId: priceId,
            quantity: 1,
          );

          final success = result['success'] as bool;
          if (!success) {
            allSuccess = false;
            anyFailure = true;
          }
        } catch (e) {
          allSuccess = false;
          anyFailure = true;
        }
      }
    }

    if (mounted) {
      setState(() => _isAddingAllToCart = false);

      if (allSuccess) {
        showSuccessSnackbar(context, 'All items added to cart successfully');
      } else if (anyFailure) {
        showSuccessSnackbar(
            context, 'Some items could not be added (maybe already in cart)');
      }
    }
  }
}
