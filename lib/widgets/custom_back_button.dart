import 'package:flutter/material.dart';
import 'package:food_delivery/widgets/custom_secondary_button.dart';
import 'package:get/get.dart';

class CustomBackButton extends StatefulWidget {
  final double height;
  final double width;
  const CustomBackButton({
    super.key,
    required this.height,
    required this.width,
  });

  @override
  State<CustomBackButton> createState() => _CustomBackButtonState();
}

class _CustomBackButtonState extends State<CustomBackButton> {
  @override
  Widget build(BuildContext context) {
    return CustomSecondaryButton(
      height: widget.height,
      width: widget.width,
      onTap: () {
        Get.back();
      },
      iconData: Icons.arrow_back,
    );
  }
}
