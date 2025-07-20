import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/models/product_model.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:happy_farm/widgets/custom_snackbar.dart';

class FilterScreen extends StatefulWidget {
  final List<CategoryModel> categories;
  final Function(String categoryId, String categoryName) onCategorySelected;
  final Function(int minPrice, int maxPrice) onPriceFilter;
  final Function(int rating) onRatingFilter;
  final Function() onApplyFilters;
  final VoidCallback onClose;

  const FilterScreen({
    Key? key,
    required this.categories,
    required this.onCategorySelected,
    required this.onPriceFilter,
    required this.onRatingFilter,
    required this.onApplyFilters,
    required this.onClose,
  }) : super(key: key);

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  RangeValues _priceRange = const RangeValues(1, 60000);
  double _minPrice = 1;
  double _maxPrice = 60000;
  int _selectedRating = 0;
  String _selectedCatId = '';
  String _selectedCatName = '';

  // Track if any filters are applied
  bool get hasFiltersApplied =>
      _selectedCatId.isNotEmpty ||
      _priceRange.start.round() != _minPrice.toInt() ||
      _priceRange.end.round() != _maxPrice.toInt() ||
      _selectedRating > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Filter",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    // Apply Button
                    ElevatedButton(
                      onPressed: hasFiltersApplied ? _applyFilters : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasFiltersApplied
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        hasFiltersApplied ? 'Apply Filters' : 'Apply Filters',
                        style: TextStyle(
                          color: hasFiltersApplied
                              ? Colors.white
                              : Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable filter content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected Filters Summary
                  if (hasFiltersApplied)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Active Filters",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (_selectedCatId.isNotEmpty)
                              _buildFilterChip(
                                _selectedCatName,
                                Colors.blue,
                                Icons.category,
                                () => setState(() {
                                  _selectedCatId = '';
                                  _selectedCatName = '';
                                }),
                              ),
                            if (_priceRange.start.round() !=
                                    _minPrice.toInt() ||
                                _priceRange.end.round() != _maxPrice.toInt())
                              _buildFilterChip(
                                '₹${_priceRange.start.round()} - ₹${_priceRange.end.round()}',
                                Colors.green,
                                Icons.price_change,
                                () => setState(() {
                                  _priceRange =
                                      RangeValues(_minPrice, _maxPrice);
                                }),
                              ),
                            if (_selectedRating > 0)
                              _buildFilterChip(
                                '$_selectedRating ★ & up',
                                Colors.orange,
                                Icons.star,
                                () => setState(() {
                                  _selectedRating = 0;
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),

                  // CATEGORY FILTER
                  _buildFilterSection(
                    title: "FILTER BY CATEGORY",
                    child: _buildCategoryFilter(),
                  ),

                  const SizedBox(height: 30),

                  // PRICE FILTER
                  _buildFilterSection(
                    title: "FILTER BY PRICE",
                    child: _buildPriceFilter(),
                  ),

                  const SizedBox(height: 30),

                  // RATING FILTER
                  _buildFilterSection(
                    title: "FILTER BY RATING",
                    child: _buildRatingFilter(),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, Color color, IconData icon, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      backgroundColor: color.withOpacity(0.1),
      avatar: Icon(icon, color: color, size: 18),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onRemove,
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildCategoryFilter() {
    if (widget.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          final isSelected = category.id == _selectedCatId;

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedCatId = '';
                  _selectedCatName = '';
                } else {
                  _selectedCatId = category.id;
                  _selectedCatName = category.name;
                }
              });
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected ? Colors.blue : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: ClipOval(
                          child: isSelected
                              ? ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    Colors.blue.withOpacity(0.3),
                                    BlendMode.srcATop,
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: category.imageUrl,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey.shade100,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.grey.shade100,
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: category.imageUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade100,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: Colors.grey.shade100,
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.blue : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      children: [
        RangeSlider(
          values: _priceRange,
          min: _minPrice,
          max: _maxPrice,
          divisions: (_maxPrice - _minPrice).toInt(),
          activeColor: Colors.green,
          inactiveColor: Colors.green.shade100,
          labels: RangeLabels(
            'Rs: ${_priceRange.start.round()}',
            'Rs: ${_priceRange.end.round()}',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _priceRange = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'From: Rs: ${_priceRange.start.round()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              'To: Rs: ${_priceRange.end.round()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      children: List.generate(5, (index) {
        int stars = 5 - index;
        bool isSelected = _selectedRating == stars;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange.shade50 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.orange : Colors.transparent,
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedRating = isSelected ? 0 : stars;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        return Icon(
                          i < stars ? Icons.star : Icons.star_border,
                          color: i < stars ? Colors.orange : Colors.grey,
                          size: 24,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '$stars & up',
                        style: TextStyle(
                          color: isSelected ? Colors.orange : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.orange,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _applyFilters() {
    if (_selectedCatId.isEmpty) {
      showInfoSnackbar(context, 'Please select a category first.');
      return;
    }

    widget.onCategorySelected(_selectedCatId, _selectedCatName);

    if (_selectedRating > 0) {
      widget.onRatingFilter(_selectedRating);
    } else if (_priceRange.start.round() != _minPrice.toInt() ||
        _priceRange.end.round() != _maxPrice.toInt()) {
      widget.onPriceFilter(_priceRange.start.round(), _priceRange.end.round());
    } else {
      // Just category filter
      // Already called above
    }

    widget.onApplyFilters();
  }
}
