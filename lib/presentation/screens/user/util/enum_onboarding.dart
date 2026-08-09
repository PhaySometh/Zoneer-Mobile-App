enum OnbordingData {
  onboarding1(
    'Find the perfect place for your future house',
    'find the best place for your dream house with your family and loved ones',
    'assets/stickers/ZoneerOnboarding1.json',
  ),
  onboarding2(
    'Fast sell your property in just one click',
    'Simplify the property sales process with just your smartphone',
    'assets/stickers/ZoneerOnboarding2.json',
  ),
  onboarding3(
    'Find your dream home with us',
    'Just search and select your favorite property you want to locate',
    'assets/stickers/ZoneerOnboarding3.json',
  );

  final String title;
  final String subtitle;
  final String lottieAsset;
  const OnbordingData(this.title, this.subtitle, this.lottieAsset);
}
