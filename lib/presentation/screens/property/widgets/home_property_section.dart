import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';
import 'package:zoneer_mobile/presentation/screens/property/property_detail_page.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/property_card.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/property_card_skeleton.dart';

/// A snapping horizontal-scroll property section with peek & haptic feedback.
///
/// [nearbyItems] — if provided, cards show distance badges (for Nearby section).
/// [propertiesAsync] — used for non-nearby sections.
/// Exactly one of these must be non-null.
class HomePropertySection extends StatefulWidget {
  final String title;
  final String emptyMessage;
  final VoidCallback onSeeAll;

  // For regular sections
  final AsyncValue<List<PropertyModel>>? propertiesAsync;

  // For nearby section: tuples of (property, distanceMeters)
  final AsyncValue<List<(PropertyModel, double)>>? nearbyAsync;

  const HomePropertySection({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.onSeeAll,
    this.propertiesAsync,
    this.nearbyAsync,
  }) : assert(
          (propertiesAsync == null) != (nearbyAsync == null),
          'Provide exactly one of propertiesAsync or nearbyAsync, not both or neither',
        );

  @override
  State<HomePropertySection> createState() => _HomePropertySectionState();
}

class _HomePropertySectionState extends State<HomePropertySection> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        _currentPage = page;
        HapticFeedback.lightImpact();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: widget.onSeeAll,
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Content
        if (widget.nearbyAsync != null)
          _buildNearbyContent(context, widget.nearbyAsync!)
        else
          _buildRegularContent(context, widget.propertiesAsync!),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRegularContent(
    BuildContext context,
    AsyncValue<List<PropertyModel>> async,
  ) {
    return async.when(
      loading: () => _buildSkeletonRow(),
      error: (_, __) => _buildError(),
      data: (properties) {
        if (properties.isEmpty) return _buildEmpty();
        final cards = properties
            .map(
              (p) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PropertyDetailPage(id: p.id),
                  ),
                ),
                child: PropertyCard(property: p),
              ),
            )
            .toList();
        return _pageViewScroll(cards);
      },
    );
  }

  Widget _buildNearbyContent(
    BuildContext context,
    AsyncValue<List<(PropertyModel, double)>> async,
  ) {
    return async.when(
      loading: () => _buildSkeletonRow(),
      error: (_, __) => _buildError(),
      data: (items) {
        if (items.isEmpty) return _buildEmpty();
        final cards = items
            .map(
              (item) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PropertyDetailPage(id: item.$1.id),
                  ),
                ),
                child: PropertyCard(
                  property: item.$1,
                  distanceMeters: item.$2,
                ),
              ),
            )
            .toList();
        return _pageViewScroll(cards);
      },
    );
  }

  Widget _pageViewScroll(List<Widget> cards) {
    return SizedBox(
      height: 200,
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: PageView.builder(
          controller: _pageController,
          clipBehavior: Clip.none,
          padEnds: false,
          itemCount: cards.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: cards[index],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonRow() {
    const skeletons = [
      PropertyCardSkeleton(),
      PropertyCardSkeleton(),
      PropertyCardSkeleton(),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: skeletons
            .map((s) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: s,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 36, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              widget.emptyMessage,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return const SizedBox(
      height: 120,
      child: Center(
        child: Text(
          'Something went wrong. Please try again.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }
}
