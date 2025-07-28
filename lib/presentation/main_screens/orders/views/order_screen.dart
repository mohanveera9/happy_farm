import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/orders/views/order_details.dart';
import 'package:happy_farm/presentation/main_screens/orders/services/order_service.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/presentation/main_screens/orders/widgets/order_shimmer.dart';
import 'package:happy_farm/widgets/without_login_screen.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  OrdersScreenState createState() => OrdersScreenState();
}

class OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  List orders = [];
  bool isLoading = true;
  bool _isLoadingMore = false;
  bool _isLoggedIn = false;
  late TabController _tabController;

  // Pagination variables
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalOrders = 0;
  bool _hasMoreOrders = true;
  final int _perPage = 10;

  late ScrollController _scrollController;

  // Enhanced color scheme
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color veryLightGreen = Color(0xFFE8F5E8);
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textMedium = Color(0xFF546E7A);

  final List<String> statusTabs = [
    'All',
    'pending',
    'confirm',
    'delivered',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: statusTabs.length, vsync: this);
    _scrollController = ScrollController();
    _setupScrollListener();
    _initializeScreen();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore && _hasMoreOrders && _currentPage < _totalPages) {
          _loadMoreOrders();
        }
      }
    });
  }

  Future<void> _initializeScreen() async {
    // Check login status first
    await _checkLoginStatus();

    // Load orders if user is logged in, otherwise just stop loading
    if (_isLoggedIn) {
      await fetchOrders();
    } else {
      // FIXED: Set loading to false when user is not logged in
      setState(() {
        isLoading = false;
      });
    }
  }

  // Public method to refresh orders from MainScreen
  Future<void> refreshOrders() async {
    await _checkLoginStatus();
    if (_isLoggedIn) {
      setState(() {
        orders = [];
        _currentPage = 1;
        _hasMoreOrders = true;
        _isLoadingMore = false;
        _totalPages = 1;
        _totalOrders = 0;
        isLoading = true;
      });
      await fetchOrders();
    } else {
      // FIXED: Also handle non-logged-in state in refresh
      setState(() {
        isLoading = false;
      });
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

  Future<void> fetchOrders() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await OrderService().fetchAllOrdersWithPagination(
        page: _currentPage,
        perPage: _perPage,
      );

      if (response == null) {
        print("No order data received");
        setState(() => isLoading = false);
        return;
      }

      setState(() {
        orders = response['orders'] ?? [];
        _totalPages = response['pagination']['totalPages'] ?? 1;
        _totalOrders = response['pagination']['totalOrders'] ?? 0;
        _hasMoreOrders = response['pagination']['hasNextPage'] ?? false;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        showErrorSnackbar(context, 'Failed to load orders');
      }
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoadingMore || !_hasMoreOrders || _currentPage >= _totalPages) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;

      final response = await OrderService().fetchAllOrdersWithPagination(
        page: nextPage,
        perPage: _perPage,
      );

      if (response != null) {
        final newOrders = response['orders'] ?? [];

        setState(() {
          if (newOrders.isNotEmpty) {
            orders.addAll(newOrders);
            _currentPage = nextPage;
          }
          _hasMoreOrders = response['pagination']['hasNextPage'] ?? false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        showErrorSnackbar(context, 'Failed to load more orders');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text("My Orders"),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? Center(child: OrderShimmer())
          : !_isLoggedIn
              ? WithoutLoginScreen(
                  icon: Icons.receipt_long_outlined,
                  title: 'My Orders',
                  subText:
                      'Login to view your orders and track your deliveries',
                )
              : Column(
                  children: [
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppTheme.primaryColor,
                        tabs: statusTabs
                            .map((status) => Tab(text: status.capitalize()))
                            .toList(),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: statusTabs.map((status) {
                          final filteredOrders = status == 'All'
                              ? orders
                              : orders
                                  .where((o) =>
                                      o['orderStatus']
                                          .toString()
                                          .toLowerCase() ==
                                      status.toLowerCase())
                                  .toList();

                          if (filteredOrders.isEmpty && !isLoading) {
                            return Center(
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
                                      Icons.inventory_2_outlined,
                                      size: 60,
                                      color: accentGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    "No ${status.toLowerCase()} orders",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: textDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "You haven't placed any orders yet",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textMedium,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: refreshOrders,
                            child: ListView.builder(
                              controller:
                                  status == 'All' ? _scrollController : null,
                              padding: EdgeInsets.all(10),
                              itemCount: filteredOrders.length +
                                  (status == 'All' && _hasMoreOrders ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index < filteredOrders.length) {
                                  final order = filteredOrders[index];
                                  return OrderCard(
                                    order: order,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OrderDetailsPage(
                                                  orderId:
                                                      order['_id'].toString()),
                                        ),
                                      );
                                    },
                                  );
                                } else {
                                  // Show loading indicator for more items
                                  return _buildLoadMoreIndicator();
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return Column(
        children: List.generate(2, (index) => _buildShimmerCartItem()),
      );
    }
    return const SizedBox.shrink();
  }
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

class OrderCard extends StatelessWidget {
  final VoidCallback onTap;
  final Map order;

  OrderCard({required this.order, required this.onTap});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'delivered':
        return AppTheme.primaryColor;
      case 'cancelled':
        return Colors.red;
      case 'shipped':
        return Colors.blue;
      case 'confirm':
        return AppTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'shipped':
        return Icons.local_shipping;
      case 'confirm':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderDate = order['date'] != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(order['date']))
        : '';
    final totalAmount =
        double.tryParse(order['amount'].toString())?.toStringAsFixed(2) ??
            '0.00';

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Order ID and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order['orderId'].toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order['orderStatus'] ?? '')
                          .withOpacity(0.1),
                      border: Border.all(
                        color: _getStatusColor(order['orderStatus'] ?? ''),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(order['orderStatus'] ?? ''),
                          color: _getStatusColor(order['orderStatus'] ?? ''),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order['orderStatus'].toString().capitalize(),
                          style: TextStyle(
                            color: _getStatusColor(order['orderStatus'] ?? ''),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(thickness: 0.8),

              /// Order Info
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _orderInfoTile("Order Date", orderDate),
                  _orderInfoTile("Items",
                      "${(order['products'] as List?)?.length ?? 0} items"),
                  _orderInfoTile(
                    "Total",
                    "₹$totalAmount",
                    color: AppTheme.primaryColor,
                    isBold: true,
                  ),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _orderInfoTile(String title, String value,
    {Color color = Colors.black87, bool isBold = false}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    ],
  );
}

extension StringExtension on String {
  String capitalize() =>
      this.isNotEmpty ? '${this[0].toUpperCase()}${this.substring(1)}' : '';
}