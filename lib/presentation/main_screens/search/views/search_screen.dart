import 'dart:async';
import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/productdetails_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/product_service.dart';
import 'package:happy_farm/presentation/main_screens/search/services/search_service.dart';
import 'package:happy_farm/utils/app_theme.dart';
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
  
  // Timer for debouncing API calls
  Timer? _searchTimer;
  
  // Minimum characters before triggering search
  static const int minSearchLength = 1;
  
  // Delay before making API call (in milliseconds)
  static const int searchDelay = 500;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    
    // Listen to text changes
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
    
    // Cancel any existing timer
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
    
    // Show loading immediately
    setState(() {
      isLoading = true;
    });
    
    // Set up a new timer
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
      // Keep only last 10 searches
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
      
      // Only update if this is still the current search query
      if (_controller.text.trim() == query) {
        setState(() {
          _searchResults = results;
          isLoading = false;
        });
        
        // Add to history only for successful searches with results
        if (results.isNotEmpty) {
          await _addToHistory(query);
        }
      }
    } catch (e) {
      // Only show error if this is still the current search query
      if (_controller.text.trim() == query) {
        setState(() {
          isLoading = false;
          _searchResults = [];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> fetchProductById(String productId) async {
    try {
      final productService = ProductService();
      final product = await productService.getProductById(productId);
      if (product != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (builder) => ProductDetails(
              product: product,
            ),
          ),
        );
      } else {
        print('No product found for ID: $productId');
      }
    } catch (e) {
      print('Error fetching product: $e');
    }
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search for products..(min ${minSearchLength} chars)',
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          suffixIcon: isLoading
              ? Container(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor!),
                    ),
                  ),
                )
              : _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
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
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                Icon(
                  Icons.history,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  "No recent searches",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Start searching for your favorite products",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
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
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Icon(
                          Icons.history,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        title: Text(
                          query,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _removeFromHistory(query),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.close,
                              color: Colors.grey[500],
                              size: 18,
                            ),
                          ),
                        ),
                        onTap: () {
                          _controller.text = query;
                          // This will trigger the search automatically
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
              Icon(
                Icons.search_off,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                "Start typing to search",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Find products from our farm",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
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
              Icon(
                Icons.edit,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                "Keep typing...",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Need at least ${minSearchLength} characters to search",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
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
              Icon(
                Icons.search_off,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                "No products found",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Try searching with different keywords",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
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

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.eco,
                      color: AppTheme.primaryColor,
                      size: 30,
                    ),
            ),
            title: Text(
              product['name'] ?? 'No Name',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (price != null)
                  Text(
                    '₹$price',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                if (product['catName'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${product['catName']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.primaryColor,
              ),
            ),
            onTap: () {
              fetchProductById(product['_id']);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchField(),
            Expanded(
              child: isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Searching...",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
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
    );
  }
}