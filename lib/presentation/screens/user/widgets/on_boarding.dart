import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import 'package:lottie/lottie.dart';

class Onboarding extends StatelessWidget {
  const Onboarding({super.key,required this.title,required this.subtitle,required this.lottieAsset});
  final String title;
  final String subtitle;
  final String lottieAsset;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Spacer(flex: 1),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Lottie.asset(
              // 'assets/stickers/ZoneerOnboarding1.json',
              lottieAsset,
              width: width * 0.8,
              height: height * 0.4
            ),
          ),
          SizedBox(height: 20),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 60),
            child: Column(
              children: [
                Text(
                  // 'Find the perfect place for your future house',
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  // 'find the best place for your dream house with your family and loved ones',
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
