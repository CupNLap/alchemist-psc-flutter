import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:student/model/batch.dart';

bool isValidJoiningQRCode(s) {
  return RegExp(r'^([^/]+)/([^/]+)$').hasMatch(s);
}

class BatchJoinPage extends StatefulWidget {
  const BatchJoinPage({super.key});

  @override
  State<BatchJoinPage> createState() => _BatchJoinPageState();
}

class _BatchJoinPageState extends State<BatchJoinPage> {
  String _scanBarcode = '';

  @override
  Widget build(BuildContext context) {
    void requestToJoinBatch(String instituteId, String batchId) {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final user = FirebaseAuth.instance.currentUser!;

      final String batchPath = 'Institute/$instituteId/Batch/$batchId';
      final String requestPath = 'Institute/$instituteId/JoinRequests';

      final DocumentReference userRef = firestore.doc('Users/${user.uid}');
      final DocumentReference batchRef = firestore.doc(batchPath);
      final CollectionReference requestRef = firestore.collection(requestPath);

      BatchJoinRequest request = BatchJoinRequest(
          userName: user.displayName!,
          batch: batchRef,
          user: userRef,
          created: Timestamp.now(),
          status: 'pending');

      requestRef.add(request.toFirestore());
    }

    void scanQR() {
      // Platform messages may fail, so we use a try/catch PlatformException.
      try {
        FlutterBarcodeScanner.scanBarcode(
                '#ff6666', 'Cancel', true, ScanMode.QR)
            .then((barcodeScanRes) {
          // validate the barcodeScanRes contains two strings separated by '/' using regex
          if (isValidJoiningQRCode(barcodeScanRes)) {
            // Join the specific batch
            var ids = barcodeScanRes.split('/');

            requestToJoinBatch(ids[0], ids[1]);

            // If the widget was removed from the tree while the asynchronous platform
            // message was in flight, we want to discard the reply rather than calling
            // setState to update our non-existent appearance.
            if (!mounted) return;
            setState(() {
              _scanBarcode = barcodeScanRes;
            });
          }
        });
      } on PlatformException {
        print('Failed to get platform version.');
      }
    }

    return Scaffold(
      body: Center(
        child: _scanBarcode.isNotEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                      "Request to Join the batch has been sent to respective admins"),
                  const Text("Please ask your admin to accept the request"),
                  Text(_scanBarcode),
                ],
              )
            : ElevatedButton(
                onPressed: () => scanQR(),
                child: const Text('Start QR scan'),
              ),
      ),
    );
  }
}
