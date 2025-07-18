import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/product_model.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/category_service.dart';

class FeaturedCategoriesWidget extends StatefulWidget {
  final Function(String categoryName) onCategorySelected;
  final double height;
  final double categorySize;
  final EdgeInsets? padding;
  final bool showTitle;
  final String title;

  const FeaturedCategoriesWidget({
    Key? key,
    required this.onCategorySelected,
    this.height = 120.0,
    this.categorySize = 70.0,
    this.padding,
    this.showTitle = true,
    this.title = 'Featured Categories',
  }) : super(key: key);

  @override
  State<FeaturedCategoriesWidget> createState() => _FeaturedCategoriesWidgetState();
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
    } catch (e) {
      print('Error loading categories: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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
        if (widget.showTitle)
          Padding(
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        
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
              Container(
                height: widget.categorySize,
                width: widget.categorySize,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
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
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  category.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: _parseColor(category.color),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: _parseColor(category.color),
                      child: const Center(
                        child: Icon(
                          Icons.category,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    );
                  },
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

  Color _parseColor(String colorString) {
    try {
      // Remove # if present and add 0xff prefix
      String cleanColor = colorString.replaceFirst('#', '');
      return Color(int.parse('0xff$cleanColor'));
    } catch (e) {
      // Return a default color if parsing fails
      return Colors.grey;
    }
  }
}