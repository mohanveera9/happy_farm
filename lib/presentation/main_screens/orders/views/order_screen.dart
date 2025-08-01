import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/orders/views/order_details.dart';
import 'package:happy_farm/presentation/main_screens/orders/services/order_service.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/presentation/main_screens/orders/widgets/order_shimmer.dart';
import 'package:happy_farm/widgets/without_login_screen.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _hasMoreOrders = true;
  final int _perPage = 10; // Increased for better UX

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
        if (!_isLoadingMore && _hasMoreOrders) {
          _loadMoreOrders();
        }
      }
    });
  }

  Future<void> _initializeScreen() async {
    await _checkLoginStatus();

    if (_isLoggedIn) {
      await fetchOrders();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> refreshOrders() async {
    await _checkLoginStatus();
    if (_isLoggedIn) {
      _resetPagination();
      await fetchOrders();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _resetPagination() {
    setState(() {
      orders = [];
      _currentPage = 1;
      _hasMoreOrders = true;
      _isLoadingMore = false;
      isLoading = true;
    });
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
        setState(() {
          isLoading = false;
          _hasMoreOrders = false;
        });
        return;
      }

      final newOrders = response['orders'] ?? [];
      
      setState(() {
        if (_currentPage == 1) {
          orders = newOrders;
        } else {
          orders.addAll(newOrders);
        }
        
        // Better logic for determining if there are more orders
        _hasMoreOrders = newOrders.length == _perPage;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        _hasMoreOrders = false;
      });
      if (mounted) {
        showErrorSnackbar(context, 'Failed to load orders');
      }
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoadingMore || !_hasMoreOrders) {
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
            // If we got fewer orders than requested, no more pages
            _hasMoreOrders = newOrders.length == _perPage;
          } else {
            _hasMoreOrders = false;
          }
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
          _hasMoreOrders = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _hasMoreOrders = false;
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
                        isScrollable: true,
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
                            return _buildEmptyState(status);
                          }

                          return RefreshIndicator(
                            onRefresh: refreshOrders,
                            child: ListView.builder(
                              controller:
                                  status == 'All' ? _scrollController : null,
                              padding: EdgeInsets.all(10),
                              itemCount: filteredOrders.length +
                                  (status == 'All' && (_hasMoreOrders || _isLoadingMore) ? 1 : 0),
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

  Widget _buildEmptyState(String status) {
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
            status == 'All' 
                ? "You haven't placed any orders yet"
                : "No orders with ${status.toLowerCase()} status",
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

  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading more orders...',
              style: TextStyle(
                color: textMedium,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    if (!_hasMoreOrders && orders.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(
          'No more orders to load',
          style: TextStyle(
            color: textMedium,
            fontSize: 14,
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
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
                  Expanded(
                    child: Text(
                      order['orderId'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                      mainAxisSize: MainAxisSize.min,
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
  return Flexible(
    child: Column(
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
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

extension StringExtension on String {
  String capitalize() =>
      this.isNotEmpty ? '${this[0].toUpperCase()}${this.substring(1)}' : '';
}