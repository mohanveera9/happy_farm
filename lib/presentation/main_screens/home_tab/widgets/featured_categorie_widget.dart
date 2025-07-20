import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/product_model.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/category_service.dart';

class FeaturedCategoriesWidget extends StatefulWidget {
  final Function(String categoryName) onCategorySelected;
  final double height;
  final double categorySize;
  final EdgeInsets? padding;
  final bool showTitle;

  const FeaturedCategoriesWidget({
    Key? key,
    required this.onCategorySelected,
    this.height = 120.0,
    this.categorySize = 70.0,
    this.padding,
    this.showTitle = true,
  }) : super(key: key);

  @override
  State<FeaturedCategoriesWidget> createState() =>
      _FeaturedCategoriesWidgetState();
}

class _FeaturedCategoriesWidgetState extends State<FeaturedCategoriesWidget> {
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final categories = await CategoryService.fetchCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isLoading = false;
      });

      // Pre-cache category images for better performance
      _preCacheImages();
    } catch (e) {
      print('Error loading categories: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Pre-cache images to improve performance
  void _preCacheImages() {
    for (final category in _categories) {
      if (category.imageUrl.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(category.imageUrl),
          context,
        );
      }
    }
  }

  Future<void> refreshCategories() async {
    await _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: widget.height,
          child: _isLoading
              ? _buildLoadingState()
              : _categories.isEmpty
                  ? _buildEmptyState()
                  : _buildCategoryList(),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: 5, // Show 5 loading placeholders
      itemBuilder: (context, index) {
        return Container(
          width: 100,
          margin: const EdgeInsets.only(right: 16.0),
          child: Column(
            children: [
              // Shimmer effect for category image
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: widget.categorySize,
                  width: widget.categorySize,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Shimmer effect for category name
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 12,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No categories available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryItem(category);
      },
    );
  }

  Widget _buildCategoryItem(CategoryModel category) {
    return GestureDetector(
      onTap: () {
        widget.onCategorySelected(category.name);
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16.0),
        child: Column(
          children: [
            Container(
              height: widget.categorySize,
              width: widget.categorySize,
              decoration: BoxDecoration(
                color: _parseColor(category.color),
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: category.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildShimmerPlaceholder(),
                  errorWidget: (context, url, error) => Container(
                    color: _parseColor(category.color),
                    child: const Center(
                      child: Icon(
                        Icons.category,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  // Cache configuration
                  fadeInDuration: const Duration(milliseconds: 300),
                  fadeOutDuration: const Duration(milliseconds: 300),
                  memCacheWidth: (widget.categorySize * 2).round(), 
                  memCacheHeight: (widget.categorySize * 2).round(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500), // Slower shimmer for loading
      child: Container(
        width: widget.categorySize,
        height: widget.categorySize,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {

      String cleanColor = colorString.replaceFirst('#', '');
      return Color(int.parse('0xff$cleanColor'));
    } catch (e) {
     
      return Colors.grey;
    }
  }
}