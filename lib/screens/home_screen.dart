import 'package:flutter/material.dart';
import 'dart:async';
import '../models/product_model.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_widget.dart';
import '../widgets/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  List<Product> _featuredProducts = [];
  List<Product> _allProducts = [];

  // Banner auto-scroll controller
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;

  // Featured products auto-scroll controller
  final ScrollController _featuredScrollController = ScrollController();
  Timer? _featuredTimer;

  // Banner data
  final List<BannerItem> _banners = [
    BannerItem(
      imageUrl:
          'https://www.indianagricultureproducts.com/images/agriculture-products-banner.jpg',
      title: 'Empower Your Farm with the Best Tools',
      buttonText: 'Explore Now',
    ),
    BannerItem(
      imageUrl:
          'https://www.agrifarming.in/wp-content/uploads/2015/05/Modern-Agriculture-Technology.jpg',
      title: 'Modern Farming Solutions for Better Yields',
      buttonText: 'Learn More',
    ),
    BannerItem(
      imageUrl:
          'https://agriculturereview.com/wp-content/uploads/2023/04/agriculture-machinery.jpg',
      title: 'Latest Machinery for Efficient Farming',
      buttonText: 'View Products',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupAutoBannerScroll();
    _setupFeaturedProductsScroll();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _featuredTimer?.cancel();
    _bannerController.dispose();
    _featuredScrollController.dispose();
    super.dispose();
  }

  void _setupAutoBannerScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients) {
        _currentBannerIndex = (_currentBannerIndex + 1) % _banners.length;
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _setupFeaturedProductsScroll() {
    _featuredTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_featuredScrollController.hasClients &&
          !_isLoading &&
          _featuredProducts.isNotEmpty) {
        double maxScroll = _featuredScrollController.position.maxScrollExtent;
        double currentScroll = _featuredScrollController.offset;
        double targetScroll = currentScroll + 200;

        if (targetScroll > maxScroll) {
          targetScroll = 0;
        }

        _featuredScrollController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _featuredProducts = Product.getFeaturedProducts();
      _allProducts = Product.sampleProducts;
      _isLoading = false;
    });
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
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: _isLoading
              ? _buildLoadingView()
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: _buildContentView(),
                ),
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
        _buildBannerCarousel(),
        _buildCategoryCards(),
        _buildSectionTitle('Featured Farming Tools', Icons.star_outline),
        _buildFeaturedProducts(),
        _buildPromoBanner(),
        _buildSectionTitle(
            'All Agricultural Items', Icons.agriculture_outlined),
        _buildAllProducts(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBannerCarousel() {
    return Container(
      height: 200.0,
      margin: const EdgeInsets.only(top: 8),
      child: PageView.builder(
        controller: _bannerController,
        itemCount: _banners.length,
        onPageChanged: (index) {
          setState(() {
            _currentBannerIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return _buildBannerItem(_banners[index]);
        },
      ),
    );
  }

  Widget _buildBannerItem(BannerItem banner) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage(banner.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              banner.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(banner.buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _banners.length,
        (index) => Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentBannerIndex == index
                ? Colors.green
                : Colors.grey.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCards() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildCategoryCard('Seeds', Icons.grass, Colors.green.shade800),
          _buildCategoryCard(
              'Fertilizers', Icons.science, Colors.brown.shade700),
          _buildCategoryCard('Tools', Icons.handyman, Colors.orange.shade800),
          _buildCategoryCard(
              'Machinery', Icons.agriculture, Colors.blue.shade800),
          _buildCategoryCard(
              'Pesticides', Icons.bug_report, Colors.red.shade800),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade800),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: Row(
              children: [
                Text('View All',
                    style: TextStyle(color: Colors.green.shade700)),
                Icon(Icons.arrow_forward,
                    size: 16, color: Colors.green.shade700),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    return Column(
      children: [
        SizedBox(
          height: 240.0,
          child: ListView.builder(
            controller: _featuredScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _featuredProducts.length,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemBuilder: (context, index) {
              return ProductCard(
                product: _featuredProducts[index],
                onTap: () => _showProductDetails(_featuredProducts[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _buildBannerIndicator(),
      ],
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      height: 120,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.green.shade800, Colors.green.shade500],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.agriculture,
              size: 140,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'SPECIAL OFFER',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '20% OFF on all Fertilizers',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green.shade800,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Shop Now'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllProducts() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _allProducts.length,
      padding: const EdgeInsets.all(12.0),
      itemBuilder: (context, index) {
        return ProductCard(
          product: _allProducts[index],
          onTap: () => _showProductDetails(_allProducts[index]),
        );
      },
    );
  }

  
  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    product.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 16,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => Navigator.pop(context),
                      color: Colors.black87,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Top Rated',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '₹${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(' ${product.rating}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(' (${(product.price * 10).toInt()} reviews)',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.description,
                    style: const TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Quantity: '),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: () {},
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                            const Text('1'),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () {},
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'In Stock',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.favorite_outline),
                          label: const Text('Wishlist'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green.shade700,
                            side: BorderSide(color: Colors.green.shade700),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.green.shade700,
                                action: SnackBarAction(
                                  label: 'View Cart',
                                  textColor: Colors.white,
                                  onPressed: () {},
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: const Text('Add to Cart'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BannerItem {
  final String imageUrl;
  final String title;
  final String buttonText;

  BannerItem({
    required this.imageUrl,
    required this.title,
    required this.buttonText,
  });
}
