import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  Future<void> initialize() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    _auth.authStateChanges().listen((user) {
      if (user != null) {
        registerTokenForCurrentUser(user);
      }
    });

    _messaging.onTokenRefresh.listen((token) async {
      final user = _auth.currentUser;
      if (user == null) return;
      await _saveToken(user.uid, token);
    });

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await registerTokenForCurrentUser(currentUser);
    }
  }

  Future<void> registerTokenForCurrentUser(User user) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM permission denied.');
      return;
    }

    if (kIsWeb) {
      debugPrint('Skipping FCM token registration on web until VAPID is set.');
      return;
    }

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('FCM token unavailable.');
      return;
    }

    await _saveToken(user.uid, token);
  }

  Future<void> _saveToken(String parentId, String token) async {
    await _firestore.collection('parents').doc(parentId).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      'Foreground FCM message: ${message.messageId}, data: ${message.data}',
    );
  }
}
