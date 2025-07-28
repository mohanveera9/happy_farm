import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/product_model.dart';
import 'package:shimmer/shimmer.dart';

class CategoryDrawer extends StatefulWidget {
  final List<CategoryModel> categories;
  final Function(String) onCategorySelected;
  final VoidCallback onFilterTap;

  const CategoryDrawer({
    Key? key,
    required this.categories,
    required this.onCategorySelected,
    required this.onFilterTap,
  }) : super(key: key);

  @override
  State<CategoryDrawer> createState() => _CategoryDrawerState();
}

class _CategoryDrawerState extends State<CategoryDrawer> {
  Map<String, bool> _expandedCategories = {};

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF5F5F5),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 56, 142, 60),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.category,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Categories',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: widget.onFilterTap,
                    icon: Icon(
                      Icons.filter_list,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            ),

            // Categories List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.categories.length,
                itemBuilder: (context, index) {
                  final category = widget.categories[index];
                  final isExpanded = _expandedCategories[category.id] ?? false;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: _buildCategoryImage(category),
                          title: Text(
                            category.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: category.children.isNotEmpty
                              ? Text(
                                  '${category.children.length} subcategories',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                          trailing: category.children.isNotEmpty
                              ? AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Color.fromARGB(255, 56, 142, 60),
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Color.fromARGB(255, 56, 142, 60),
                                ),
                          onTap: () {
                            if (category.children.isNotEmpty) {
                              setState(() {
                                _expandedCategories[category.id] = !isExpanded;
                              });
                            } else {
                              widget.onCategorySelected(category.name);
                            }
                          },
                        ),

                        // Subcategories
                        if (isExpanded && category.children.isNotEmpty)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              children: category.children.map((subCategory) {
                                return ListTile(
                                  contentPadding: const EdgeInsets.only(
                                    left: 60,
                                    right: 16,
                                    top: 4,
                                    bottom: 4,
                                  ),
                                  dense: true,
                                  title: Text(
                                    subCategory.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: Colors.grey,
                                  ),
                                  onTap: () {
                                    widget.onCategorySelected(subCategory.name);
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryImage(CategoryModel category) {
    if (category.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: category.images.first,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (context, url) => Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 40,
              height: 40,
              color: Colors.white,
            ),
          ),
          errorWidget: (context, url, error) => _buildPlaceholderImage(),
        ),
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color.fromARGB(255, 56, 142, 60).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const Icon(
        Icons.category,
        color: Color.fromARGB(255, 56, 142, 60),
        size: 20,
      ),
    );
  }
}
