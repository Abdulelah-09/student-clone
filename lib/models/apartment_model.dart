class ApartmentModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;

  ApartmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  // دالة لتحويل بيانات الشقة من Firebase إلى كائن ApartmentModel
  factory ApartmentModel.fromMap(Map<String, dynamic> data, String id) {
    return ApartmentModel(
      id: id,
      title: data['title'],
      description: data['description'],
      imageUrl: data['imageUrl'],
    );
  }

  // دالة لتحويل كائن ApartmentModel إلى Map لتخزينه في Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}
