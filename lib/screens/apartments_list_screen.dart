import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_apartment_screen.dart';
import 'booking_management_screen.dart';
import 'profile_screen.dart';
import 'apartment_details_screen.dart';

class ApartmentsListScreen extends StatefulWidget {
  @override
  _ApartmentsListScreenState createState() => _ApartmentsListScreenState();
}

class _ApartmentsListScreenState extends State<ApartmentsListScreen> {
  int _currentIndex = 0; // مؤشر الشاشة الحالية

  // قائمة الشاشات
  final List<Widget> _screens = [
    ApartmentsListScreenContent(), // محتوى قائمة الشقق
    AddApartmentScreen(), // شاشة إضافة شقة
    BookingManagementScreen(), // شاشة إدارة الحجوزات
    ProfileScreen(), // شاشة الملف الشخصي
  ];

  // تغيير الشاشة عند الضغط على أيقونة في الشريط السفلي
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()), // عنوان حسب الشاشة الحالية
        backgroundColor: Colors.blueAccent,
      ),
      body: _screens[_currentIndex], // عرض الشاشة الحالية
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: Colors.blueAccent, // خلفية الشريط السفلي
        selectedItemColor: Colors.black, // لون العنصر المحدد
        unselectedItemColor: Colors.black, // لون العناصر غير المحددة
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الشقق',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'إضافة شقة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'الحجوزات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'الملف الشخصي',
          ),
        ],
      ),
    );
  }

  // دالة لإرجاع عنوان الشاشة بناءً على الشاشة الحالية
  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return "قائمة الشقق";
      case 1:
        return "إضافة شقة";
      case 2:
        return "إدارة الحجوزات";
      case 3:
        return "الملف الشخصي";
      default:
        return "تطبيق الشقق";
    }
  }
}

class ApartmentsListScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('apartments').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "لا توجد شقق مرفوعة حالياً.",
              style: TextStyle(fontSize: 18.0),
            ),
          );
        }

        // عرض قائمة الشقق
        final apartments = snapshot.data!.docs;

        return ListView.builder(
          itemCount: apartments.length,
          itemBuilder: (context, index) {
            final apartment = apartments[index];
            final data = apartment.data() as Map<String, dynamic>;
            final bool isSharing = data['isSharing'] ?? false; // قراءة حالة "مشاركة السكن"

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: data['imageUrl'] != null && data['imageUrl'] != ''
                    ? Image.network(
                  data['imageUrl'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
                    : Icon(Icons.image, size: 50),
                title: Text(data['title'] ?? 'بدون عنوان'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['description'] ?? 'بدون وصف'),
                    if (isSharing) // عرض النص إذا كانت ميزة مشاركة السكن مفعلة
                      Text(
                        "توفر مشاركة السكن",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                trailing: Text("${data['price'] ?? 'غير محدد'} ريال"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApartmentDetailsScreen(
                        data: data,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
