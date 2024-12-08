import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConfirmedBookingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('الحجوزات المؤكدة')),
        body: Center(child: Text('يرجى تسجيل الدخول لعرض الحجوزات المؤكدة')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('الحجوزات المؤكدة'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('confirmedBookings')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('لا توجد حجوزات مؤكدة حالياً'),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['apartmentTitle'] ?? 'بدون عنوان'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("السعر: ${data['price']} ريال"),
                    Text("التاريخ: ${data['bookingDate']}"),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
