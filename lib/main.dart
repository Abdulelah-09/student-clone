import 'package:app25/screens/apartments_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/sign_up_screen.dart';
import 'package:app25/screens/profile_screen.dart';
import 'screens/add_apartment_screen.dart';
import 'screens/booking_management_screen.dart'; // إضافة شاشة إدارة الحجوزات
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(androidProvider: AndroidProvider.debug);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Estate App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(), // الشاشة الرئيسية
      routes: {
        '/signup': (context) => SignUpScreen(),
        '/profile': (context) => ProfileScreen(),
        '/apartments': (context) => ApartmentsListScreen(),
        '/add_apartment': (context) => AddApartmentScreen(),
        '/bookings': (context) => BookingManagementScreen(), // إضافة المسار الجديد
      },
    );
  }
}
