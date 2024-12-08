class UserModel {
  final String uid;
  final String email;
  final String phoneNumber;
  final String userType;
  final String? imageUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.phoneNumber,
    required this.userType,
    this.imageUrl,
  });

  // دالة لتحويل بيانات المستخدم من Firebase إلى كائن UserModel
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      userType: data['userType'],
      imageUrl: data['imageUrl'],
    );
  }

  // دالة لتحويل كائن UserModel إلى Map لتخزينه في Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'phoneNumber': phoneNumber,
      'userType': userType,
      'imageUrl': imageUrl,
    };
  }
}
