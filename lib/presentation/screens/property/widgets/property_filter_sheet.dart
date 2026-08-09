import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/presentation/viewmodels/property/property_filter_provider.dart';

class PropertyFilterSheet extends ConsumerStatefulWidget {
  const PropertyFilterSheet({super.key});

  @override
  ConsumerState<PropertyFilterSheet> createState() =>
      _PropertyFilterSheetState();
}

class _PropertyFilterSheetState extends ConsumerState<PropertyFilterSheet> {
  late String? _selectedType;
  late RangeValues _priceRange;
  late int? _selectedBeds;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(propertyFilterProvider);
    _selectedType = filter.propertyType;
    _priceRange = RangeValues(filter.minPrice, filter.maxPrice);
    _selectedBeds = filter.beds;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Filter',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedType = null;
                    _priceRange = const RangeValues(10, 800);
                    _selectedBeds = null;
                  });
                },
                child: const Text(
                  'Reset',
                  style: TextStyle(color: Color(0xFFE91E63)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Property Type
          const Text(
            'Property Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPropertyTypeButton('Dorm', 'dorm', Icons.apartment),
              _buildPropertyTypeButton('Room', 'room', Icons.meeting_room),
              _buildPropertyTypeButton('Apart', 'apartment', Icons.business),
              _buildPropertyTypeButton('House', 'house', Icons.home),
            ],
          ),
          const SizedBox(height: 24),

          // Price Range
          const Text(
            'Price Range',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _priceRange,
            min: 10,
            max: 800,
            divisions: 79,
            activeColor: const Color(0xFFE91E63),
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${_priceRange.start.round()}',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  '\$${_priceRange.end.round()}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Beds
          const Text(
            'Beds',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBedsButton(1),
              _buildBedsButton(2),
              _buildBedsButton(3),
              _buildBedsButton(4),
              _buildBedsButton(5, label: '5+'),
              _buildBedsButton(null, label: 'Any'),
            ],
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref
                    .read(propertyFilterProvider.notifier)
                    .updatePropertyType(_selectedType);
                ref
                    .read(propertyFilterProvider.notifier)
                    .updatePriceRange(_priceRange.start, _priceRange.end);
                ref
                    .read(propertyFilterProvider.notifier)
                    .updateBeds(_selectedBeds);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Filter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeButton(String label, String value, IconData icon) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = isSelected ? null : value;
        });
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE91E63).withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFE91E63)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? const Color(0xFFE91E63) : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFFE91E63) : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBedsButton(int? value, {String? label}) {
    final isSelected = _selectedBeds == value;
    final displayLabel = label ?? value.toString();

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBeds = value;
        });
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE91E63) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          displayLabel,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
