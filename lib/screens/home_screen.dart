import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_widget.dart';
import '../widgets/custom_app_bar.dart';
import '../models/banner_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:happy_farm/screens/productdetails_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  List<FeaturedProduct> _featuredProducts = [];
  List<AllProduct> _allProducts = [];
  int _visibleFeaturedCount = 2;
  int _visibleAllCount = 2;

  @override
  void initState() {
    super.initState();
    fetchAllProducts();
    fetchFeaturedProducts();
  }

  Future<void> fetchFeaturedProducts() async {
    const url =
        'http://10.0.2.2:8000/api/products/featured'; // Replace with your real URL
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      final List<FeaturedProduct> products = data
          .map((product) => FeaturedProduct.fromJson(
              product)) // Assuming Product model has a `fromJson` method
          .toList();
      setState(() {
        _featuredProducts = products;
        _isLoading = false; // Update loading status
      });
    } else {
      throw Exception('Failed to load featured products');
    }
  }

  Future<void> fetchAllProducts() async {
    const url =
        'http://10.0.2.2:8000/api/products'; // Replace with your real URL
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List data = decoded['products'];

      final List<AllProduct> products = data
          .map((product) => AllProduct.fromJson(
              product)) // Assuming Product model has a `fromJson` method
          .toList();
      setState(() {
        _allProducts = products;
        _isLoading = false; // Update loading status
      });
    } else {
      throw Exception('Failed to load all products');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        onMenuTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingView()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildContentView(),
              ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const ShimmerHomeScreen();
  }

  Widget _buildContentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AutoScrollBanner(),
        _buildSectionTitle('Featured Products'),
        _buildFeaturedProducts(),
        _buildSectionTitle('All Products'),
        _buildAllProducts(),
      ],
    );
  }

  Widget _buildFeaturedProducts() {
    if (_featuredProducts.isEmpty) {
      return const Center(child: Text('No featured products available.'));
    }

    final visibleProducts =
        _featuredProducts.take(_visibleFeaturedCount).toList();

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
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
                        FeaturedProductDetails(product: product),
                  ),
                );
              },
              child: FeaturedProductCard(product: product),
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
    );
  }

  Widget _buildAllProducts() {
    if (_allProducts.isEmpty) {
      return const Center(child: Text('No products available.'));
    }

    final visibleProducts = _allProducts.take(_visibleAllCount).toList();

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
          ),
          itemCount: visibleProducts.length,
          itemBuilder: (context, index) {
            final product = visibleProducts[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllProductDetails(product: product),
                  ),
                );
              },
              child: AllProductCard(product: product),
            );
          },
        ),
        if (_visibleAllCount < _allProducts.length)
          TextButton(
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
      ],
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

  @override
  void initState() {
    super.initState();
    fetchBanners();
  }

  Future<void> fetchBanners() async {
    const url =
        'http://10.0.2.2:8000/api/homeBanner/'; // Replace with your real URL
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      final banners = data.map((e) => BannerModel.fromJson(e)).toList();
      setState(() {
        _banners = banners;
      });

      // Start auto-scroll once banners are loaded
      _startAutoScroll();
    } else {
      throw Exception('Failed to load banners');
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_banners.isEmpty) return;

      int nextPage = _currentIndex + 1;

      if (nextPage >= _banners.length) {
        // Jump to first page without animation
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
      height: 250.0,
      child: _banners.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    image: DecorationImage(
                      image: NetworkImage(_banners[index].imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
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
