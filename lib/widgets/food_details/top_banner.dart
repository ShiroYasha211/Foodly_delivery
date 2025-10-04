import 'package:flutter/material.dart';

import '../custom_back_button.dart';

class TopBanner extends StatelessWidget {
  final int foodIndex;
  const TopBanner({super.key, required this.foodIndex});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: SafeArea(
          child: SizedBox(
            height: size.height * 0.31,
            width: size.width,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomBackButton(
                      height: size.height * 0.04,
                      width: size.width * 0.09,
                    ),
                    // FavoriteButton(
                    //   foodIndex: foodIndex,
                    //   height: size.height * 0.04,
                    //   width: size.width * 0.09,
                    // ),
                  ],
                ),
                const Spacer(),
                const Align(
                  alignment: Alignment.center,
                  // child: CachedNetworkImage(
                  //   imageUrl: food[foodIndex].imgUrl,
                  //   placeholder: (context, url) => Container(
                  //     alignment: Alignment.center,
                  //     child: CircularProgressIndicator(),
                  //   ),
                  //   errorWidget: (context, url, error) => Container(
                  //     color: Colors.grey[300],
                  //     child: Icon(Icons.error, color: Colors.red),
                  //   ),
                  //   fit: BoxFit.contain,
                  //   height: size.height * 0.27,
                  //   width: size.width,
                  // ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
