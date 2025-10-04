class ProfileModel {
  final int id;
  final String name;
  final String email;
  final String imgUrl;
  final String address;

  ProfileModel({
    required this.address,
    required this.id,
    required this.name,
    required this.email,
    required this.imgUrl,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      imgUrl: json['imgUrl'],
      address: json['address'],
    );
  }
}
