import 'package:flutter/material.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';

class BannerZoneer extends StatelessWidget {
  final VoidCallback? onBrowseNow;

  const BannerZoneer({super.key, this.onBrowseNow});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 15, top: 15, bottom: 15),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Text & Button
                SizedBox(
                  width: constraints.maxWidth * 0.55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover your perfect place to stay today.',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.background,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Browse your favorite property.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.background,
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.contrast,
                          foregroundColor: AppColors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                        ),
                        onPressed: onBrowseNow,
                        child: const Text(
                          'Browse Now!',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),

                // Mascot image positioned to the right
                Positioned(
                  right: 0,
                  bottom: -25,
                  child: Image.asset(
                    'assets/images/Zoneer_mascot.png',
                    height: 120,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
