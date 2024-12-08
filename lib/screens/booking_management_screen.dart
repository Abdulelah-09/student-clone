import 'package:flutter/material.dart';
import 'PendingRequestsScreen.dart';
import 'ConfirmedBookingsScreen.dart';

class BookingManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة الحجوزات'),
      ),
      body: ListView(
        children: [
          // الطلبات المعلقة
          ListTile(
            leading: Icon(Icons.pending_actions),
            title: Text('الطلبات المعلقة'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PendingRequestsScreen(),
                ),
              );
            },
          ),
          // الطلبات المؤكدة
          ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('الحجوزات المؤكدة'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfirmedBookingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
