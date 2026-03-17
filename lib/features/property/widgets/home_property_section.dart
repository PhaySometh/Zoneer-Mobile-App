import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/core/providers/navigation_provider.dart';
import 'package:zoneer_mobile/features/property/models/property_model.dart';
import 'package:zoneer_mobile/features/property/viewmodels/property_filter_provider.dart';
import 'package:zoneer_mobile/features/property/views/property_detail_page.dart';
import 'package:zoneer_mobile/features/property/widgets/property_card.dart';

class HomePropertySection extends ConsumerWidget {
  final String title;
  final String sectionType;
  final AsyncValue<List<PropertyModel>> propertiesAsync;

  const HomePropertySection({
    super.key,
    required this.title,
    required this.sectionType,
    required this.propertiesAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(propertyFilterProvider.notifier)
                    .updatePropertyType(sectionType);
                ref
                    .read(navigationProvider.notifier)
                    .changeTab(NavigationTab.map);
              },
              child: Text('See all'),
            ),
          ],
        ),
        propertiesAsync.when(
          data: (properties) => Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: properties
                    .map(
                      (property) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          child: PropertyCard(property: property),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PropertyDetailPage(id: property.id),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
