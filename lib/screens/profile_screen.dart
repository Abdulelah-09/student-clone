import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;
  String name = ''; // إضافة متغير لتخزين الاسم
  String email = '';
  String phoneNumber = '';
  String userType = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _getUserData();
  }

  Future<void> _getUserData() async {
    if (user != null) {
      DocumentSnapshot userData = await _firestore.collection('users').doc(user!.uid).get();
      setState(() {
        name = userData['name']; // جلب الاسم
        email = userData['email'];
        phoneNumber = userData['phoneNumber'];
        userType = userData['userType'];
        isLoading = false;
      });
    }
  }

  void _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("الملف الشخصي"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              "مرحبا بك، $name", // عرض الاسم هنا
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              email,
              style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
            ),
            SizedBox(height: 32.0),
            _buildProfileInfoRow("الاسم", name), // عرض الاسم في الصفوف
            Divider(color: Colors.grey[300]),
            _buildProfileInfoRow("رقم الهاتف", phoneNumber),
            Divider(color: Colors.grey[300]),
            _buildProfileInfoRow("نوع المستخدم", userType),
            Divider(color: Colors.grey[300]),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(vertical: 16.0),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                "تسجيل الخروج",
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16.0, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
