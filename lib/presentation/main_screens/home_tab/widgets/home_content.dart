import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/shimmer_widget.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/featured_categorie_widget.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/auto_scroll_banner_widget.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/all_products_widget.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/widgets/featured_products_widget.dart';

class HomeContent extends StatelessWidget {
  final bool isLoading;
  final Future<void> Function()? onRefresh;
  final ScrollController scrollController;
  final GlobalKey<State<StatefulWidget>> bannerKey;
  final GlobalKey<State<StatefulWidget>> featuredProductsKey;
  final GlobalKey<State<StatefulWidget>> allProductsKey;
  final Future<void> Function(dynamic product) onProductTap;
  final Function(String) onCategorySelected;

  const HomeContent({
    Key? key,
    required this.isLoading,
    this.onRefresh,
    required this.scrollController,
    required this.bannerKey,
    required this.featuredProductsKey,
    required this.allProductsKey,
    required this.onProductTap,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ShimmerHomeScreen();
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (onRefresh != null) {
          await onRefresh!();
        }
      },
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: _buildContentView(),
      ),
    );
  }

  Widget _buildContentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner Section
        AutoScrollBannerWidget(
          key: bannerKey,
          height: 180.0,
          autoScrollDuration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16.0),
          borderRadius: BorderRadius.circular(12.0),
          onBannerTap: () {},
        ),
        
        // Featured Categories Section
        _buildSectionTitle('Featured Categories'),
        FeaturedCategoriesWidget(
          onCategorySelected: onCategorySelected,
        ),
        
        // Featured Products Section
        _buildSectionTitle('Featured Products'),
        FeaturedProductsWidget(
          key: featuredProductsKey,
          onProductTap: onProductTap,
          parentScrollController: scrollController,
          initialVisibleCount: 4,
        ),
        
        // All Products Section
        _buildSectionTitle('All Products'),
        AllProductsWidget(
          key: allProductsKey,
          onProductTap: onProductTap,
          parentScrollController: scrollController,
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}