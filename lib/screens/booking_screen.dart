import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> apartmentData;

  BookingScreen({required this.apartmentData});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool isBooking = false;
  String? selectedDate;
  List<String> availableDates = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableDates();
  }

  Future<void> _fetchAvailableDates() async {
    // جلب التواريخ المتاحة من Firestore
    final doc = await FirebaseFirestore.instance
        .collection('apartments')
        .doc(widget.apartmentData['id'])
        .get();

    if (doc.exists) {
      final data = doc.data();
      setState(() {
        availableDates = List<String>.from(data?['availableDates'] ?? []);
      });
    } else {
      setState(() {
        availableDates = _generateDatesForOneYear();
      });
    }
  }

  List<String> _generateDatesForOneYear() {
    final today = DateTime.now();
    final dates = <String>[];
    for (int i = 0; i < 365; i++) {
      final date = today.add(Duration(days: i));
      dates.add(date.toIso8601String().split('T')[0]); // حفظ التاريخ فقط
    }
    return dates;
  }

  Future<void> _bookApartment() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى تسجيل الدخول لإتمام الحجز')),
      );
      return;
    }

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى اختيار موعد للحجز')),
      );
      return;
    }

    setState(() {
      isBooking = true;
    });

    try {
      // جلب بيانات المستخدم من Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String userName = userDoc['name'] ?? 'مستخدم مجهول';

      // إضافة الحجز إلى مجموعة bookings
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'ownerId': widget.apartmentData['ownerId'],
        'name': userName,
        'apartmentId': widget.apartmentData['id'],
        'apartmentTitle': widget.apartmentData['title'],
        'price': widget.apartmentData['price'],
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'bookingDate': selectedDate,
      });

      // تحديث التواريخ المتاحة في Firestore
      availableDates.remove(selectedDate);
      await FirebaseFirestore.instance
          .collection('apartments')
          .doc(widget.apartmentData['id'])
          .update({'availableDates': availableDates});

      // رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حجز الشقة بنجاح، الطلب قيد المراجعة.')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحجز: $e')),
      );
    } finally {
      setState(() {
        isBooking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("حجز الشقة"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "تفاصيل الشقة:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("العنوان: ${widget.apartmentData['title'] ?? 'بدون عنوان'}"),
            Text("الوصف: ${widget.apartmentData['description'] ?? 'بدون وصف'}"),
            Text("السعر: ${widget.apartmentData['price'] ?? 'غير محدد'} ريال"),
            SizedBox(height: 16),
            availableDates.isEmpty
                ? Text(
              "لا توجد مواعيد متاحة حالياً.",
              style: TextStyle(color: Colors.red),
            )
                : DropdownButtonFormField<String>(
              value: selectedDate,
              items: availableDates.map((date) {
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
            ),
            SizedBox(height: 16),
            isBooking
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _bookApartment,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("تأكيد الحجز"),
            ),
          ],
        ),
      ),
    );
  }
}
