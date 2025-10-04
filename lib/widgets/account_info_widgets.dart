import 'package:flutter/material.dart';

Widget accountInfoWidgets(
  BuildContext context, {
  required String name,
  required int number,
}) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      children: [
        Text(
          number.toString(),
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          name,
          style: Theme.of(
            context,
          ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}

Widget itemTappedTile(
  BuildContext context, {
  required String title,
  required IconData icon,
  String? subtitle,
}) {
  final size = MediaQuery.of(context).size;
  return Column(
    children: [
      const Divider(),
      ListTile(
        onTap: () {},
        leading: Icon(
          icon,
          size: size.height * 0.04,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: Icon(
          Icons.chevron_right,
          size: size.height * 0.03,
          color: Theme.of(context).primaryColor,
        ),
      ),
    ],
  );
}
