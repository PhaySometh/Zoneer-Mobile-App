import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zoneer_mobile/presentation/viewmodels/property/media_viewmodel.dart';
import 'package:zoneer_mobile/presentation/screens/property/widgets/fullscreen_image_viewer.dart';

class ImageWidget extends ConsumerStatefulWidget {
  final String thumbnail;
  final String propertyId;

  const ImageWidget({
    super.key,
    required this.thumbnail,
    required this.propertyId,
  });

  @override
  ConsumerState<ImageWidget> createState() => ImageWidgetState();
}

class ImageWidgetState extends ConsumerState<ImageWidget> {
  final PageController pageController = PageController();
  int currentPage = 0;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _openFullscreenViewer(BuildContext context, List<String> images) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FullscreenImageViewer(images: images, initialIndex: currentPage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(mediaViewmodelProvider(widget.propertyId));

    return mediaAsync.when(
      data: (media) {
        final images = [widget.thumbnail, ...media.map((e) => e.url)];

        return GestureDetector(
          onTap: () => _openFullscreenViewer(context, images),
          child: SizedBox(
            height: 360,
            width: double.infinity,
            child: ClipRect(
              child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: images.length,
                  onPageChanged: (index) => setState(() => currentPage = index),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.black12,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black12,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 64,
                            color: Colors.black38,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Dots indicator
                if (images.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (index) {
                        bool isActive = index == currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.white : Colors.black26,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      },
      loading: () => SizedBox(
        height: 250,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) =>
          SizedBox(height: 250, child: Center(child: Text(err.toString()))),
    );
  }
}
