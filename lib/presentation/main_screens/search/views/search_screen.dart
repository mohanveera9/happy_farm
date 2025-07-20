import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/productdetails_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/product_service.dart';
import 'package:happy_farm/presentation/main_screens/search/services/search_service.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final SearchService _searchService = SearchService();

  List<Map<String, dynamic>> _searchResults = [];
  List<String> _searchHistory = [];
  bool isLoading = false;

  Timer? _searchTimer;

  static const int minSearchLength = 1;
  static const int searchDelay = 500;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color veryLightGreen = Color(0xFFE8F5E8);
  static const Color orangeAccent = Color(0xFFFF7043);
  static const Color blueAccent = Color(0xFF42A5F5);
  static const Color purpleAccent = Color(0xFF9C27B0);
  static const Color backgroundGray = Color(0xFFF8F9FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textMedium = Color(0xFF546E7A);
  static const Color textLight = Color(0xFF90A4AE);

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _controller.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _controller.removeListener(_onSearchTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final query = _controller.text.trim();

    _searchTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        isLoading = false;
      });
      return;
    }

    if (query.length < minSearchLength) {
      setState(() {
        _searchResults = [];
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    _searchTimer = Timer(Duration(milliseconds: searchDelay), () {
      _performSearch(query);
    });
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory = prefs.getStringList('searchHistory') ?? [];
    setState(() {});
  }

  Future<void> _addToHistory(String query) async {
    if (query.isEmpty || query.length < minSearchLength) return;
    final prefs = await SharedPreferences.getInstance();
    if (!_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.take(10).toList();
      }
      await prefs.setStringList('searchHistory', _searchHistory);
      setState(() {});
    }
  }

  Future<void> _removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(query);
    await prefs.setStringList('searchHistory', _searchHistory);
    setState(() {});
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty || query.length < minSearchLength) {
      setState(() {
        isLoading = false;
        _searchResults = [];
      });
      return;
    }

    try {
      final results = await _searchService.searchProducts(query: query);

      if (_controller.text.trim() == query) {
        setState(() {
          _searchResults = results;
          isLoading = false;
        });

        if (results.isNotEmpty) {
          await _addToHistory(query);
        }
      }
    } catch (e) {
      if (_controller.text.trim() == query) {
        setState(() {
          isLoading = false;
          _searchResults = [];
        });
        showErrorSnackbar(context, 'No products found!');
      }
    }
  }

  // Enhanced navigation method with better error handling
  Future<void> _navigateToProductDetails(Map<String, dynamic> product) async {
    try {
      final productService = ProductService();
      final productId = product['_id'] ?? product['id'];

      if (productId == null || productId.toString().isEmpty) {
        showErrorSnackbar(context, 'Invalid product ID!');
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: SizedBox(
                height: 30,
                width: 30,
                child: CircularProgressIndicator(
                  color: Color(0xFF298C4C),
                ),
              ),
            ),
          ),
        ),
      );

      try {
        final fullProduct =
            await productService.getProductById(productId.toString());

        // Dismiss loading indicator
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetails(
              product: fullProduct,
            ),
          ),
        );
      } catch (productError) {
        
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        String errorMessage = 'Error loading product details!';
        if (productError.toString().contains('Product not found')) {
          errorMessage = 'Product not found!';
        } else if (productError.toString().contains('Authentication failed')) {
          errorMessage = 'Please log in again to view product details.';
        } else if (productError.toString().contains('Network error')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        showErrorSnackbar(context, errorMessage);
        print('Product fetch error: $productError');
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      showErrorSnackbar(context, 'Unexpected error occurred!');
      print('Navigation error: $e');
    }
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardWhite, Color(0xFFFAFBFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        style: const TextStyle(
          fontSize: 16,
          color: textDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search for fresh products...',
          hintStyle: TextStyle(
            color: textLight,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: accentGreen,
              size: 26,
            ),
          ),
          suffixIcon: isLoading
              ? Container(
                  padding: const EdgeInsets.all(12),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(accentGreen),
                    ),
                  ),
                )
              : _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: textMedium,
                      ),
                      onPressed: () {
                        _controller.clear();
                        _searchTimer?.cancel();
                        setState(() {
                          _searchResults = [];
                          isLoading = false;
                        });
                      },
                    )
                  : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return _searchHistory.isEmpty
        ? Center(
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
                    Icons.history_rounded,
                    size: 60,
                    color: accentGreen,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "No recent searches",
                  style: TextStyle(
                    fontSize: 20,
                    color: textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Start searching for your favorite products",
                  style: TextStyle(
                    fontSize: 16,
                    color: textMedium,
                  ),
                ),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  "Recent Searches",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _searchHistory.length,
                  itemBuilder: (context, index) {
                    final query = _searchHistory[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: veryLightGreen,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 6),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: veryLightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            color: accentGreen,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          query,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                        trailing: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _removeFromHistory(query),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.red.shade400,
                              size: 18,
                            ),
                          ),
                        ),
                        onTap: () {
                          _controller.text = query;
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && !isLoading) {
      if (_controller.text.trim().isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 60,
                  color: blueAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Start typing to search",
                style: TextStyle(
                  fontSize: 20,
                  color: textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Find fresh products from our farm",
                style: TextStyle(
                  fontSize: 16,
                  color: textMedium,
                ),
              ),
            ],
          ),
        );
      } else if (_controller.text.trim().length < minSearchLength) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 60,
                  color: orangeAccent,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Keep typing...",
                style: TextStyle(
                  fontSize: 20,
                  color: textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Need at least $minSearchLength characters to search",
                style: TextStyle(
                  fontSize: 16,
                  color: textMedium,
                ),
              ),
            ],
          ),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 60,
                  color: purpleAccent,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "No products found",
                style: TextStyle(
                  fontSize: 20,
                  color: textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Try searching with different keywords",
                style: TextStyle(
                  fontSize: 16,
                  color: textMedium,
                ),
              ),
            ],
          ),
        );
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        final imageUrl =
            product['images']?.isNotEmpty == true ? product['images'][0] : null;
        final price = product['prices']?.isNotEmpty == true
            ? product['prices'][0]['actualPrice']
            : null;

        return GestureDetector(
          onTap: () => _navigateToProductDetails(product),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.grey.shade400,
                              size: 24,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey.shade400,
                              size: 24,
                            ),
                          ),
                          fadeInDuration: const Duration(milliseconds: 200),
                          fadeOutDuration: const Duration(milliseconds: 200),
                        ),
                      )
                    : Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
              ),
              title: Text(
                product['name'] ?? 'No Name',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (price != null)
                    Text(
                      '₹$price',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.green,
                      ),
                    ),
                  if (product['catName'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${product['catName']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              // Removed the duplicate onTap handler
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Column(
            children: [
              _buildSearchField(),
              Expanded(
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: veryLightGreen,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(accentGreen),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              "Searching...",
                              style: TextStyle(
                                fontSize: 18,
                                color: textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isNotEmpty || _controller.text.isNotEmpty
                        ? _buildSearchResults()
                        : _buildHistoryList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
