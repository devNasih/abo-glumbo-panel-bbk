import 'package:aboglumbo_bbk_panel/styles/images.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class LoginCarouselWidget extends StatefulWidget {
  const LoginCarouselWidget({super.key});

  @override
  State<LoginCarouselWidget> createState() => _LoginCarouselWidgetState();
}

class _LoginCarouselWidgetState extends State<LoginCarouselWidget> {
  int currentIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  final List<String> imgList = [
    AppImages.workerArtLogin,
    // AppImages.wemonWorker,
    // AppImages.livingRoom,
  ];
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          items: imgList
              .map(
                (item) => Container(
                  height: 286,
                  width: 290,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(item),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              )
              .toList(),
          carouselController: _controller,
          options: CarouselOptions(
            height: 286.0,
            autoPlay: false,
            enlargeCenterPage: true,
            autoPlayCurve: Curves.easeInQuad,
            enableInfiniteScroll: false,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            viewportFraction: 1,
            onPageChanged: (index, reason) {
              setState(() {
                currentIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 35),
        // AnimatedSmoothIndicator(
        //   activeIndex: currentIndex,
        //   curve: Curves.linear,
        //   count: imgList.length,
        //   effect: ExpandingDotsEffect(
        //     expansionFactor: 1.1,
        //     activeDotColor: Colors.white,
        //     dotColor: Colors.white.withOpacity(0.3),
        //     dotHeight: 6,
        //     dotWidth: 6,
        //     spacing: 8,
        //   ),
        //   onDotClicked: (index) {
        //     _controller.animateToPage(index);
        //   },
        // ),
      ],
    );
  }
}
