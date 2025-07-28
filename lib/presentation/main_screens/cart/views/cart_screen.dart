import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/cart/models/cart_model.dart';
import 'package:happy_farm/presentation/main_screens/cart/views/checkout_screen.dart';
import 'package:happy_farm/presentation/main_screens/cart/services/cart_service.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/productdetails_screen.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';
import 'package:happy_farm/widgets/without_login_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartItem> _cartItems = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isLoggedIn = false;
  Set<String> _updatingItemIds = {};
  Set<String> _deletingItemIds = {};
  Set<String> _updatingAdd = {};
  Set<String> _updatingRemove = {};
  bool _cartWasModified = false;

  // Pagination variables
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  bool _hasMoreItems = true;
  final int _perPage = 5;

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _setupScrollListener();
    _checkLoginAndFetchCart();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore && _hasMoreItems && _currentPage < _totalPages) {
          _loadMoreCartItems();
        }
      }
    });
  }

  void _onCartModified() {
    setState(() {
      _cartWasModified = true;
    });
  }

  Future<void> _checkLoginAndFetchCart() async {
    // Check if user is logged in
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');

    setState(() {
      _isLoggedIn = token != null && userId != null;
    });

    if (_isLoggedIn) {
      _fetchCart();
    } else {
      // If not logged in, just stop loading
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCart() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await CartService.fetchCartWithPagination(
        page: _currentPage,
        perPage: _perPage,
      );

      setState(() {
        _cartItems = response['items'] ?? [];
        _totalPages = response['totalPages'] ?? 1;
        _totalItems = response['totalItems'] ?? 0;
        _hasMoreItems = response['hasNextPage'] ?? false;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showErrorSnackbar(context, 'Failed to load cart items');
      }
    }
  }

  Future<void> _loadMoreCartItems() async {
    if (_isLoadingMore || !_hasMoreItems || _currentPage >= _totalPages) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;

      final response = await CartService.fetchCartWithPagination(
        page: nextPage,
        perPage: _perPage,
      );

      final newItems = response['items'] ?? [];

      setState(() {
        if (newItems.isNotEmpty) {
          _cartItems.addAll(newItems);
          _currentPage = nextPage;
        }
        _hasMoreItems = response['hasNextPage'] ?? false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        showErrorSnackbar(context, 'Failed to load more cart items');
      }
    }
  }

  Future<void> _refreshCart() async {
    setState(() {
      _cartItems = [];
      _currentPage = 1;
      _hasMoreItems = true;
      _isLoadingMore = false;
      _totalPages = 1;
      _totalItems = 0;
    });
    await _fetchCart();
  }

  Future<void> _handleUpdateCartItem({
    required String cartItemId,
    int? newQuantity,
    String? priceId,
  }) async {
    setState(() => _updatingItemIds.add(cartItemId));

    try {
      final updated = await CartService.updateCartItem(
        cartItemId: cartItemId,
        quantity: newQuantity,
        priceId: priceId,
      );

      final index = _cartItems.indexWhere((e) => e.id == cartItemId);
      if (index != -1) {
        setState(() => _cartItems[index] = updated);
      }
      showSuccessSnackbar(context, "Cart Updated");
    } catch (e) {
      showErrorSnackbar(context, '$e');
    } finally {
      if (mounted) {
        setState(() => _updatingItemIds.remove(cartItemId));
      }
    }
  }

  int _calculateTotal() {
    return _cartItems.fold(0, (sum, item) => sum + item.subTotal.toInt());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _cartWasModified ? 'cart_updated' : null);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(245, 245, 245, 1),
        appBar: AppBar(
          title: const Text("My Cart"),
          centerTitle: true,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, _cartWasModified ? 'cart_updated' : null);
            },
          ),
        ),
        body: _isLoading
            ? Center(child: Lottie.asset('assets/lottie/cartloading.json'))
            : !_isLoggedIn
                ? WithoutLoginScreen(
                    title: 'cart',
                    subText:
                        'Login to add products to your cart and mange your orders',
                    icon: Icons.shopping_cart_outlined,
                  )
                : _cartItems.isEmpty && !_isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Lottie.asset('assets/lottie/emptyCart.json'),
                            const SizedBox(height: 16),
                            Text(
                              'Your cart is empty!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshCart,
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(12),
                                itemCount: _cartItems.length +
                                    (_hasMoreItems ? 1 : 0) +
                                    1, // +1 for payment details
                                itemBuilder: (context, index) {
                                  if (index < _cartItems.length) {
                                    return _buildCartItem(_cartItems[index]);
                                  } else if (index == _cartItems.length &&
                                      _hasMoreItems) {
                                    return _buildLoadMoreIndicator();
                                  } else {
                                    return _buildPaymentDetailsSection();
                                  }
                                },
                              ),
                            ),
                            if (_cartItems.isNotEmpty)
                              _buildBottomBar(_calculateTotal()),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return Column(
        children: List.generate(2, (index) => _buildShimmerCartItem()),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 0),
      ],
    );
  }

  Widget _buildShimmerCartItem() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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

  Widget _buildPaymentDetailsSection() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildPaymentDetails(_totalItems, _calculateTotal()),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCartItem(CartItem item) {
    int itemIndex = _cartItems.indexOf(item);
    int countInStock = item.product.prices.first.countInStock;
    double actualPrice = item.product.prices.first.actualPrice;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetails(product: item.product),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.product.images.first,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹${actualPrice.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Subtotal: ₹${item.subTotal.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: _deletingItemIds.contains(item.id)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          )
                        : const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deletingItemIds.contains(item.id)
                        ? null
                        : () async {
                            setState(() {
                              _deletingItemIds.add(item.id);
                            });

                            try {
                              final msg =
                                  await CartService.deleteCartItem(item.id);

                              if (mounted) {
                                showSuccessSnackbar(context, msg);
                                // Remove the item from the list instead of refetching
                                setState(() {
                                  _cartItems.removeWhere(
                                      (cartItem) => cartItem.id == item.id);
                                  _totalItems--;
                                });
                              }
                              _onCartModified();
                            } catch (e) {
                              if (mounted) {
                                showErrorSnackbar(context, '$e');
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _deletingItemIds.remove(item.id);
                                });
                              }
                            }
                          },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        icon: _updatingRemove.contains(item.id)
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.remove_circle_outline),
                        color: item.quantity == 1
                            ? Colors.grey
                            : AppTheme.primaryColor,
                        onPressed: (item.quantity == 1 ||
                                _updatingRemove.contains(item.id))
                            ? null
                            : () async {
                                final newQty = item.quantity - 1;

                                setState(() => _updatingRemove.add(item.id));

                                try {
                                  final updatedItem =
                                      await CartService.updateCartItem(
                                    cartItemId: item.id,
                                    quantity: newQty,
                                  );
                                  setState(() {
                                    _cartItems[itemIndex] = updatedItem;
                                  });
                                  _onCartModified();
                                } catch (e) {
                                  showErrorSnackbar(context, '$e');
                                } finally {
                                  if (mounted) {
                                    setState(
                                        () => _updatingRemove.remove(item.id));
                                  }
                                }
                              },
                      ),
                      Text(item.quantity.toString()),
                      IconButton(
                        icon: _updatingAdd.contains(item.id)
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_circle_outline),
                        color: item.quantity == countInStock
                            ? Colors.grey
                            : Colors.deepOrange,
                        onPressed: (item.quantity == countInStock ||
                                _updatingAdd.contains(item.id))
                            ? null
                            : () async {
                                final newQty = item.quantity + 1;

                                setState(() => _updatingAdd.add(item.id));

                                try {
                                  final updatedItem =
                                      await CartService.updateCartItem(
                                    cartItemId: item.id,
                                    quantity: newQty,
                                  );
                                  setState(() {
                                    _cartItems[itemIndex] = updatedItem;
                                  });
                                  _onCartModified();
                                } catch (e) {
                                  showErrorSnackbar(context, '$e');
                                } finally {
                                  if (mounted) {
                                    setState(
                                        () => _updatingAdd.remove(item.id));
                                  }
                                }
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(int itemCount, int total) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Payment Details",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _paymentRow("Price ($itemCount items)", total),
          _paymentRow("Discount", 0),
          _paymentRow("Delivery Charges", "FREE"),
          const Divider(),
          _paymentRow("Total Amount", total, isBold: true),
        ],
      ),
    );
  }

  Widget _paymentRow(String title, dynamic value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value is String ? value : "₹$value",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(int total) {
    return SafeArea(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: "₹$total\n",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                children: const [
                  TextSpan(
                    text: "View price details",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final totalAmount = _cartItems.fold(
                    0, (sum, item) => sum + item.subTotal.toInt());
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(
                      cartItems: _cartItems,
                      totalAmount: totalAmount,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Proceed",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
