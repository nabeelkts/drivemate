import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> notifications = [];

  @override
  void initState() {
    super.initState();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _firestore.collection('notifications').snapshots().listen((snapshot) {
      setState(() {
        notifications = snapshot.docs;
      });
    });
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd-MM-yy hh:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _deleteNotification(String docId) async {
    try {
      await _firestore.collection('notifications').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notification: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index].data();
          final docId = notifications[index].id;
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            elevation: 3,
            child: ListTile(
              title: Text(notification['title'] ?? 'No Title'),
              subtitle: Text(
                '${notification['details'] ?? 'No Details'}\nDate: ${_formatDate(notification['date'] ?? '')}',
              ),
              trailing: IconButton(
                icon: Icon(Icons.close),
                onPressed: () => _deleteNotification(docId),
              ),
              onTap: () {
                // Handle tap if needed, e.g., navigate to details
              },
            ),
          );
        },
      ),
    );
  }
}
