import 'package:flutter/material.dart';

class PropertyItem extends StatelessWidget {
  final String propertyName;
  final String propertyValue;
  final IconData icon;
  const PropertyItem({
    super.key,
    required this.propertyName,
    required this.propertyValue,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          propertyName,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(color: Colors.grey),
        ),
        Row(
          children: [
            Text(
              propertyValue,
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
