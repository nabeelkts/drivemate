import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Debug page to test Firestore access and diagnose permission issues
class FirestoreDebugPage extends StatefulWidget {
  const FirestoreDebugPage({super.key});

  @override
  State<FirestoreDebugPage> createState() => _FirestoreDebugPageState();
}

class _FirestoreDebugPageState extends State<FirestoreDebugPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> logs = [];
  bool isLoading = false;

  void addLog(String message) {
    setState(() {
      logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
  }

  Future<void> testFirestoreAccess() async {
    setState(() {
      isLoading = true;
      logs.clear();
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        addLog('❌ No user logged in!');
        setState(() => isLoading = false);
        return;
      }

      addLog('✅ Logged in as: ${user.uid}');
      addLog('   Email: ${user.email}');

      // Test 1: Try to read users collection
      addLog('\n📋 Test 1: Reading users/{userId} document...');
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          addLog('✅ User document exists');
          addLog('   Data: ${userDoc.data()?.toString().substring(0, 100)}...');
        } else {
          addLog('⚠️ User document does not exist');
        }
      } catch (e) {
        addLog('❌ Error reading user document: $e');
      }

      // Test 2: Try to read students subcollection
      addLog('\n📋 Test 2: Reading students subcollection...');
      try {
        final studentsSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('students')
            .limit(5)
            .get();
        addLog('✅ Students query successful');
        addLog('   Found ${studentsSnapshot.docs.length} documents');
        if (studentsSnapshot.docs.isNotEmpty) {
          final firstDoc = studentsSnapshot.docs.first.data();
          addLog('   First doc keys: ${firstDoc.keys.join(', ')}');
        }
      } catch (e) {
        addLog('❌ Error reading students: $e');
      }

      // Test 3: Try to read licenseonly subcollection
      addLog('\n📋 Test 3: Reading licenseonly subcollection...');
      try {
        final licenseSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('licenseonly')
            .limit(5)
            .get();
        addLog('✅ LicenseOnly query successful');
        addLog('   Found ${licenseSnapshot.docs.length} documents');
      } catch (e) {
        addLog('❌ Error reading licenseonly: $e');
      }

      // Test 4: Try to read endorsement subcollection
      addLog('\n📋 Test 4: Reading endorsement subcollection...');
      try {
        final endorsementSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('endorsement')
            .limit(5)
            .get();
        addLog('✅ Endorsement query successful');
        addLog('   Found ${endorsementSnapshot.docs.length} documents');
      } catch (e) {
        addLog('❌ Error reading endorsement: $e');
      }

      // Test 5: Try to read vehicleDetails subcollection
      addLog('\n📋 Test 5: Reading vehicleDetails subcollection...');
      try {
        final vehicleSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('vehicleDetails')
            .limit(5)
            .get();
        addLog('✅ VehicleDetails query successful');
        addLog('   Found ${vehicleSnapshot.docs.length} documents');
      } catch (e) {
        addLog('❌ Error reading vehicleDetails: $e');
      }

      // Test 6: Try to read recentActivity subcollection
      addLog('\n📋 Test 6: Reading recentActivity subcollection...');
      try {
        final activitySnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('recentActivity')
            .limit(5)
            .get();
        addLog('✅ RecentActivity query successful');
        addLog('   Found ${activitySnapshot.docs.length} documents');
      } catch (e) {
        addLog('❌ Error reading recentActivity: $e');
      }

      // Test 7: Check security rules by trying to write
      addLog('\n📋 Test 7: Testing write permissions...');
      try {
        final testRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('testCollection')
            .doc('testDoc');
        await testRef.set(
            {'test': 'data', 'timestamp': DateTime.now().toIso8601String()});
        addLog('✅ Write test successful');

        // Clean up
        await testRef.delete();
        addLog('✅ Cleanup successful');
      } catch (e) {
        addLog('❌ Error writing: $e');
      }
    } catch (e) {
      addLog('❌ Unexpected error: $e');
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Debug'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : testFirestoreAccess,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.bug_report),
              label: const Text('Run Firestore Tests'),
              onPressed: isLoading ? null : testFirestoreAccess,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Click the button to test Firestore access',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final isError = log.contains('❌');
                        final isWarning = log.contains('⚠️');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            log,
                            style: TextStyle(
                              color: isError
                                  ? Colors.redAccent
                                  : isWarning
                                      ? Colors.orangeAccent
                                      : Colors.greenAccent,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
