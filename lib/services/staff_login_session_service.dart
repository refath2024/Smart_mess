import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class StaffLoginSessionService {
  static Future<void> logSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final staffDoc = await FirebaseFirestore.instance
        .collection('staff_state')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();
    if (staffDoc.docs.isEmpty) return;
    final baNo = staffDoc.docs.first.data()['ba_no']?.toString();
    if (baNo == null) return;

    // Device info
    String device = 'Unknown';
    try {
      if (kIsWeb) {
        device = 'Web Browser';
      } else if (Platform.isAndroid) {
        final android = await DeviceInfoPlugin().androidInfo;
        device = 'Android ${android.model} (${android.device})';
      } else if (Platform.isIOS) {
        final ios = await DeviceInfoPlugin().iosInfo;
        device = 'iOS ${ios.utsname.machine} (${ios.name})';
      } else if (Platform.isWindows) {
        device = 'Windows';
      } else if (Platform.isMacOS) {
        device = 'macOS';
      } else if (Platform.isLinux) {
        device = 'Linux';
      }
    } catch (e) {
      debugPrint('Device info error: $e');
    }

    // Location
    String location = 'Unknown';
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        debugPrint('Location services are disabled.');
      } else {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever) {
          debugPrint('Location permissions are permanently denied.');
        } else if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied by user.');
        } else if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition();
          location =
              '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }

    await FirebaseFirestore.instance
        .collection('staff_login_sessions')
        .doc(baNo)
        .collection('sessions')
        .add({
      'timestamp': FieldValue.serverTimestamp(),
      'device': device,
      'location': location,
    });
  }
}
