import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddApartmentScreen extends StatefulWidget {
  @override
  _AddApartmentScreenState createState() => _AddApartmentScreenState();
}

class _AddApartmentScreenState extends State<AddApartmentScreen> {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  File? _imageFile;
  bool isUploading = false;
  String? imageUrl;

  // متغيرات لحفظ المدخلات
  String title = '';
  String description = '';
  String price = '';
  bool isSharing = false; // متغير لتحديد حالة "مشاركة السكن"

  /// دالة لاختيار الصورة من المعرض
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError("حدث خطأ أثناء اختيار الصورة: $e");
    }
  }

  /// دالة لرفع الصورة وحفظ بيانات الشقة
  Future<void> _uploadApartmentData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showError('يرجى تسجيل الدخول أولاً');
      return;
    }

    try {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        if (_imageFile == null) {
          _showError('يرجى اختيار صورة للشقة.');
          return;
        }

        setState(() {
          isUploading = true;
        });

        String fileName =
            'apartments/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

        // رفع الصورة
        await storageRef.putFile(_imageFile!);

        // الحصول على الرابط المباشر للصورة
        imageUrl = await storageRef.getDownloadURL();

        // إنشاء قائمة تواريخ لمدة سنة قادمة
        List<String> availableDates = [];
        DateTime currentDate = DateTime.now();
        for (int i = 0; i < 365; i++) {
          availableDates.add(currentDate.add(Duration(days: i)).toIso8601String().split('T')[0]);
        }

        // إضافة الشقة إلى Firestore
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('apartments')
            .add({
          'title': title,
          'description': description,
          'price': price,
          'imageUrl': imageUrl,
          'ownerId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'isSharing': isSharing,
          'availableDates': availableDates, // إضافة قائمة التواريخ
        });

        // تحديث المستند لإضافة معرف الشقة
        await docRef.update({'apartmentId': docRef.id});

        _showSuccess('تم إضافة الشقة بنجاح ومعرف الشقة: ${docRef.id}');
        _resetForm();
      }
    } on FirebaseException catch (e) {
      _showError('حدث خطأ أثناء رفع البيانات: ${e.message}');
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }


  /// دالة لعرض رسالة خطأ
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.red))),
    );
  }

  /// دالة لعرض رسالة نجاح
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.green))),
    );
  }

  /// إعادة تعيين النموذج
  void _resetForm() {
    setState(() {
      _imageFile = null;
      imageUrl = null;
      title = '';
      description = '';
      price = '';
      isSharing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("إضافة شقة جديدة"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // حقل إدخال العنوان
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "العنوان",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "يرجى إدخال عنوان الشقة";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    title = value!;
                  },
                ),
                SizedBox(height: 16.0),

                // حقل إدخال الوصف
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "الوصف",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "يرجى إدخال وصف الشقة";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    description = value!;
                  },
                ),
                SizedBox(height: 16.0),

                // حقل إدخال السعر
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "السعر",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "يرجى إدخال سعر الشقة";
                    }
                    if (double.tryParse(value) == null) {
                      return "يرجى إدخال رقم صحيح للسعر";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    price = value!;
                  },
                ),
                SizedBox(height: 16.0),

                // عرض الصورة المختارة أو زر لاختيار صورة
                _imageFile == null
                    ? Text("لم يتم اختيار صورة")
                    : Image.file(_imageFile!, height: 150),
                SizedBox(height: 16.0),

                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text("اختر صورة"),
                ),
                SizedBox(height: 16.0),

                // مفتاح تبديل "مشاركة السكن"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("مشاركة السكن"),
                    Switch(
                      value: isSharing,
                      onChanged: (value) {
                        setState(() {
                          isSharing = value;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16.0),

                // زر رفع البيانات
                isUploading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _uploadApartmentData,
                  child: Text("إضافة الشقة"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
