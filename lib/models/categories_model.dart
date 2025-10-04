class CategoriesModel {
  final int id;
  final String title;
  final String imgPath;

  CategoriesModel({
    required this.id,
    required this.title,
    required this.imgPath,
  });

  factory CategoriesModel.fromJson(Map<String, dynamic> json) {
    return CategoriesModel(
      id: json['id'],
      title: json['title'],
      imgPath: json['imgPath'],
    );
  }
}

List<CategoriesModel> categories = [];
