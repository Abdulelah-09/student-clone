import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApartmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  ApartmentDetailsScreen({required this.data});

  @override
  _ApartmentDetailsScreenState createState() => _ApartmentDetailsScreenState();
}

class _ApartmentDetailsScreenState extends State<ApartmentDetailsScreen> {
  String? selectedDate; // لتخزين التاريخ المختار
  bool isBooking = false; // لتحديد إذا كان الحجز قيد التنفيذ

  // جلب قائمة المواعيد المتاحة من Firestore
  Stream<List<String>> fetchAvailableDates() {
    return FirebaseFirestore.instance
        .collection('apartments') // جلب المواعيد من وثيقة الشقة
        .doc(widget.data['apartmentId']) // استخدم apartmentId
        .snapshots()
        .map((doc) {
      if (doc.data() == null || doc['availableDates'] == null) {
        return [];
      }
      return List<String>.from(doc['availableDates']);
    });
  }

  // دالة مساعدة لعرض الرسائل
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _bookApartment() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('يرجى تسجيل الدخول لإتمام الحجز');
      return;
    }

    if (selectedDate == null) {
      showMessage('يرجى اختيار موعد للحجز');
      return;
    }

    if (widget.data['apartmentId'] == null || widget.data['apartmentId'] == '') {
      showMessage('معرف الشقة غير متوفر');
      return;
    }

    setState(() {
      isBooking = true;
    });

    try {
      // عرض الـ apartmentId للتأكد من قيمته
      print("Apartment ID: ${widget.data['apartmentId']}");

      // إضافة الحجز إلى مجموعة bookings
      final bookingDoc = await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'ownerId': widget.data['ownerId'], // تأكد من تمرير ownerId في بيانات الشقة
        'apartmentId': widget.data['apartmentId'],
        'apartmentTitle': widget.data['title'] ?? 'بدون عنوان',
        'price': widget.data['price'] ?? 0,
        'bookingDate': selectedDate,
        'status': 'pending', // حالة الطلب المبدئية
        'timestamp': FieldValue.serverTimestamp(),
      });

      // إضافة الطلب إلى مجموعة pendingRequests الخاصة بمالك الشقة
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.data['ownerId']) // معرف مالك الشقة
          .collection('pendingRequests') // المجموعة الفرعية
          .doc(bookingDoc.id) // نفس معرف الحجز
          .set({
        'bookingId': bookingDoc.id,
        'userId': user.uid,
        'userName': user.displayName ?? 'مستخدم مجهول',
        'apartmentTitle': widget.data['title'] ?? 'بدون عنوان',
        'price': widget.data['price'] ?? 0,
        'status': 'pending', // حالة الطلب
        'bookingDate': selectedDate,
        'timestamp': FieldValue.serverTimestamp(),
      });

      showMessage('تم حجز الشقة بنجاح! الطلب قيد المراجعة.');
      Navigator.pop(context); // الرجوع إلى الشاشة السابقة
    } catch (e) {
      showMessage('حدث خطأ أثناء الحجز. يرجى المحاولة لاحقاً.');
      print('Error during booking: $e');
    } finally {
      setState(() {
        isBooking = false;
      });
    }
  }


  @override
  void initState() {
    super.initState();
    // تأجيل التحقق من البيانات حتى تكتمل واجهة المستخدم
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.data['apartmentId'] == null || widget.data['apartmentId'] == '') {
        showMessage('لا يمكن عرض بيانات الشقة بدون معرف.');
        Navigator.pop(context); // العودة إلى الشاشة السابقة
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data['title'] ?? 'تفاصيل الشقة'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: widget.data['imageUrl'] != null && widget.data['imageUrl'] != ''
                  ? Image.network(widget.data['imageUrl'], height: 200, fit: BoxFit.cover)
                  : Icon(Icons.image, size: 200),
            ),
            SizedBox(height: 16),
            Text(
              widget.data['title'] ?? 'بدون عنوان',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(widget.data['description'] ?? 'بدون وصف'),
            SizedBox(height: 8),
            Text("السعر: ${widget.data['price'] ?? 'غير محدد'} ريال"),
            SizedBox(height: 16),

            // Dropdown لاختيار المواعيد
            StreamBuilder<List<String>>(
              stream: fetchAvailableDates(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('لا توجد مواعيد متاحة حالياً.', style: TextStyle(color: Colors.red));
                }

                return DropdownButtonFormField<String>(
                  value: selectedDate,
                  items: snapshot.data!.map((date) {
                    return DropdownMenuItem(
                      value: date,
                      child: Text(date),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDate = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "اختر موعد الحجز",
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            SizedBox(height: 16),

            // زر الحجز
            isBooking
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _bookApartment,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('تأكيد الحجز'),
            ),
          ],
        ),
      ),
    );
  }
}
