import 'package:flutter/material.dart';
import 'package:food_delivery/controllers/favorite_controller.dart';
import 'package:food_delivery/models/food_item.dart';
import 'package:get/get.dart';

class FavoriteButton extends StatefulWidget {
  final FoodItem foodItem;
  final Function(bool)? onFavoriteChanged;
  final double height;
  final double width;

  const FavoriteButton({
    super.key,
    required this.height,
    required this.width,
    required this.foodItem,
    this.onFavoriteChanged,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final FavoriteController _favoriteController = Get.find();
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = _favoriteController.isFoodFavorite(widget.foodItem.id);
  }

  void _toggleFavorite() async {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    if (widget.onFavoriteChanged != null) {
      widget.onFavoriteChanged!(_isFavorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFavorite,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: _isFavorite
              ? Theme.of(context).primaryColor
              : Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          color: _isFavorite ? Colors.white : Colors.grey[600],
          size: widget.height * 0.6,
        ),
      ),
    );
  }
}
