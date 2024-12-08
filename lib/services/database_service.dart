import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/apartment_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // حفظ بيانات المستخدم في Firestore
  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      print("Error saving user: $e");
    }
  }

  // جلب بيانات المستخدم من Firestore
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
    } catch (e) {
      print("Error getting user: $e");
    }
    return null;
  }

  // إضافة شقة جديدة إلى Firestore
  Future<void> addApartment({
    required String title,
    required String description,
    required double price,
    required String imageUrl,
    required String ownerId,
  }) async {
    try {
      await _firestore.collection('apartments').add({
        'title': title,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'ownerId': ownerId,
      });
    } catch (e) {
      print("Error adding apartment: $e");
    }
  }

  // جلب قائمة الشقق من Firestore كـ Stream
  Stream<List<ApartmentModel>> getApartments() {
    return _firestore.collection('apartments').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ApartmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // تحديث بيانات شقة معينة
  Future<void> updateApartment(String apartmentId, {
    String? title,
    String? description,
    double? price,
    String? imageUrl,
  }) async {
    try {
      Map<String, dynamic> data = {};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (imageUrl != null) data['imageUrl'] = imageUrl;

      await _firestore.collection('apartments').doc(apartmentId).update(data);
    } catch (e) {
      print("Error updating apartment: $e");
    }
  }

  // حذف شقة من Firestore
  Future<void> deleteApartment(String apartmentId) async {
    try {
      await _firestore.collection('apartments').doc(apartmentId).delete();
    } catch (e) {
      print("Error deleting apartment: $e");
    }
  }
}
