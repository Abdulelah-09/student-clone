import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PendingRequestsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('الطلبات المعلقة')),
        body: Center(child: Text('يرجى تسجيل الدخول لعرض الطلبات المعلقة')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('الطلبات المعلقة'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings') // مجموعة الحجوزات
            .where('status', isEqualTo: 'pending') // الطلبات بحالة معلق
            .where('ownerId', isEqualTo: user.uid) // الطلبات الخاصة بالمستخدم الحالي
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('لا توجد طلبات معلقة حالياً'),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              return ListTile(
                leading: Icon(Icons.apartment),
                title: Text(data['apartmentTitle'] ?? 'شقة بدون عنوان'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("السعر: ${data['price'] ?? 'غير محدد'} ريال"),
                    Text("التاريخ: ${data['bookingDate'] ?? 'غير محدد'}"),
                    Text("اسم صاحب الطلب: ${data['name'] ?? 'غير معروف'}"),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        _approveRequest(doc.id, data['userId']); // تمرير معرف الحجز ومعرف المستخدم
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        _rejectRequest(doc.id);
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  /// دالة للموافقة على الطلب
  Future<void> _approveRequest(String bookingId, String userId) async {
    try {
      // تحديث حالة الطلب في مجموعة bookings إلى "approved"
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': 'approved'});

      // جلب بيانات الحجز من مجموعة bookings
      DocumentSnapshot bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (bookingSnapshot.exists) {
        Map<String, dynamic> bookingData =
        bookingSnapshot.data() as Map<String, dynamic>;

        // إضافة الحجز إلى مجموعة confirmedBookings الخاصة بالمستخدم الذي قام بالحجز
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId) // معرف المستخدم
            .collection('confirmedBookings') // المجموعة الفرعية
            .doc(bookingId) // نفس معرف الحجز
            .set({
          'apartmentTitle': bookingData['apartmentTitle'],
          'price': bookingData['price'],
          'bookingDate': bookingData['bookingDate'],
          'timestamp': FieldValue.serverTimestamp(),
        });

        // حذف الطلب من مجموعة pendingRequests (اختياري)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(bookingData['ownerId']) // معرف مالك الشقة
            .collection('pendingRequests')
            .doc(bookingId)
            .delete();

        print('تمت الموافقة على الطلب وإضافته إلى الحجوزات المؤكدة.');
      } else {
        print('الطلب غير موجود.');
      }
    } catch (e) {
      print('حدث خطأ أثناء الموافقة على الطلب: $e');
    }
  }

  /// دالة لرفض الطلب
  Future<void> _rejectRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(requestId)
          .update({'status': 'rejected'});

      print('تم رفض الطلب بنجاح.');
    } catch (e) {
      print('حدث خطأ أثناء رفض الطلب: $e');
    }
  }
}
