import 'package:flutter/material.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';

class SearchFilterSheet extends StatefulWidget {
  const SearchFilterSheet({super.key, this.initialFilters});

  final Map<String, dynamic>? initialFilters;

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  static const RangeValues _defaultPriceRange = RangeValues(0, 10000);
  static const int _defaultBeds = 1;
  static const int _defaultBaths = 1;
  static const String _defaultType = 'Any';
  static const String _defaultSection = 'all';
  static const List<(String label, String value)> _propertyTypes = [
    ('Any', 'Any'),
    ('Home', 'house'),
    ('Room', 'room'),
    ('Condo', 'condo'),
    ('Apartment', 'apartment'),
  ];
  static const List<(String label, String value)> _sections = [
    ('All', 'all'),
    ('Nearby', 'nearby'),
    ('Phnom Penh', 'phnom_penh'),
    ('Siem Reap', 'siem_reap'),
  ];

  late RangeValues priceRange;
  late int beds;
  late int baths;
  late String selectedType;
  late String selectedSection;

  String _normalizeType(String? rawType) {
    final normalized = rawType?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty || normalized == 'any') {
      return _defaultType;
    }
    final match = _propertyTypes.where((type) => type.$2 == normalized);
    return match.isEmpty ? _defaultType : normalized;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFilters;
    priceRange = (initial?['priceRange'] as RangeValues?) ?? _defaultPriceRange;
    beds = (initial?['beds'] as int?) ?? _defaultBeds;
    baths = (initial?['baths'] as int?) ?? _defaultBaths;
    selectedType = _normalizeType(initial?['selectedType'] as String?);
    selectedSection = (initial?['section'] as String?) ?? _defaultSection;
  }

  void _reset() {
    setState(() {
      priceRange = _defaultPriceRange;
      beds = _defaultBeds;
      baths = _defaultBaths;
      selectedType = _defaultType;
      selectedSection = _defaultSection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 12,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Location ──────────────────────────────────────────
            _SectionLabel('Location'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sections
                  .map(
                    (s) => _FilterChip(
                      label: s.$1,
                      selected: selectedSection == s.$2,
                      onTap: () => setState(() => selectedSection = s.$2),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 24),

            // ── Price Range ───────────────────────────────────────
            _SectionLabel('Price Range'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PriceBadge('\$${priceRange.start.round()}'),
                const Text(
                  '—',
                  style: TextStyle(color: AppColors.grey, fontSize: 16),
                ),
                _PriceBadge('\$${priceRange.end.round()}'),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.12),
                rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 10,
                ),
                trackHeight: 4,
              ),
              child: RangeSlider(
                values: priceRange,
                min: 0,
                max: 10000,
                divisions: 100,
                labels: RangeLabels(
                  '\$${priceRange.start.round()}',
                  '\$${priceRange.end.round()}',
                ),
                onChanged: (values) => setState(() => priceRange = values),
              ),
            ),

            const SizedBox(height: 24),

            // ── Bedrooms ──────────────────────────────────────────
            _SectionLabel('Bedrooms'),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (i) {
                final val = i + 1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: '$val+',
                    selected: beds == val,
                    onTap: () => setState(() => beds = val),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // ── Bathrooms ─────────────────────────────────────────
            _SectionLabel('Bathrooms'),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (i) {
                final val = i + 1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: '$val+',
                    selected: baths == val,
                    onTap: () => setState(() => baths = val),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // ── Property Type ─────────────────────────────────────
            _SectionLabel('Property Type'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _propertyTypes
                  .map(
                    (propertyType) => _FilterChip(
                      label: propertyType.$1,
                      selected: selectedType == propertyType.$2,
                      onTap: () =>
                          setState(() => selectedType = propertyType.$2),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 32),

            // ── Apply Button ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                  'priceRange': priceRange,
                  'beds': beds,
                  'baths': baths,
                  'selectedType': selectedType,
                  'section': selectedSection,
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE0E0E0),
            width: 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final String text;
  const _PriceBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
