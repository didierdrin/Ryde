import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/ride_notification.dart';
import 'package:ryde_rw/service/local_storage_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/utils/contants.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ryde_rw/firebase_options.dart';
import 'package:ryde_rw/models/notification.dart' as notification_model;
import 'package:flutter/material.dart' show Color;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Received background message: ${message.messageId}');
  print('Message data: ${message.data}');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService {
  static final fireMessage = FirebaseMessaging.instance;
  static final firestore = FirebaseFirestore.instance;
  static final collection = collections.notifications;
  static final rideNotificationsCollection = 'ride_notifications';
  static final notificationsPlugin = FlutterLocalNotificationsPlugin();
  static Function(Map<String, dynamic>)? onNotificationTapped;

  static Future<void> initialize() async {
    try {
      print('Initializing NotificationService...');

      // Request notification permissions
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('Notification permission status: ${settings.authorizationStatus}');

      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received foreground message: ${message.messageId}');
        print('Message data: ${message.data}');
        showNotification(message);
      });

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Initialize local notifications
      await notificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      // Create collections if they don't exist
      print('Creating notification collections...');
      final collections = [collection, rideNotificationsCollection];
      for (final collectionName in collections) {
        try {
          // First check if collection exists
          final collectionRef = firestore.collection(collectionName);
          final querySnapshot = await collectionRef.limit(1).get();

          if (querySnapshot.docs.isEmpty) {
            print('Collection $collectionName does not exist, creating it...');
            // Create a dummy document
            final docRef = await collectionRef.add({
              'temp': true,
              'created_at': FieldValue.serverTimestamp(),
              'collection_initialized': true,
            });
            print('Created dummy document with ID: ${docRef.id}');

            // Immediately delete the dummy document
            await docRef.delete();
            print(
              'Deleted dummy document, collection $collectionName is now initialized',
            );
          } else {
            print('Collection $collectionName already exists');
          }
        } catch (e) {
          print('Error initializing collection $collectionName: $e');
          // Don't rethrow here, try to continue with other collections
        }
      }

      print('NotificationService initialized successfully');
    } catch (e, stackTrace) {
      print('Error initializing NotificationService: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> fireMessageBackgroundHandler(
    RemoteMessage message,
  ) async {
    if (message.notification != null) {
      showNotification(message);
    }
  }

  static Future<void> sendNotification(Map<String, dynamic> data) async {
    try {
      print('Attempting to send notification to Firestore...');
      print('Data: $data');

      // Update the field name in the data
      if (data['user_id'] != null) {
        data['recipient_id'] = data['user_id'];
        data.remove('user_id');
      }

      // Add to regular notifications collection
      final docRef = await firestore.collection(collection).add({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
      });

      print('Notification sent successfully with ID: ${docRef.id}');

      // Also send push notification
      print('Sending push notification...');
      final message = RemoteMessage(
        notification: RemoteNotification(
          title: data['title'] ?? '',
          body: data['body'] ?? '',
        ),
        data: data['data'] ?? {},
      );

      await showNotification(message);
      print('Push notification sent successfully');
    } catch (e, stackTrace) {
      print('Error sending notification: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to send notification: $e');
    }
  }

  static Future<void> deleteAllNotifications(
    List<notification_model.UserNotification> notifications,
  ) async {
    try {
      final batch = firestore.batch();
      for (var notification in notifications) {
        batch.delete(firestore.collection(collection).doc(notification.id));
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete notifications: $e');
    }
  }

  static Future<void> readNotifications(List<String> notificationIds) async {
    try {
      final batch = firestore.batch();
      for (var id in notificationIds) {
        batch.update(firestore.collection(collection).doc(id), {
          'is_read': true,
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark notifications as read: $e');
    }
  }

  static final userNotificationStream =
      StreamProvider<List<notification_model.UserNotification>>((ref) {
        final userId = ref.read(userProvider)?.id ?? '';
        print('Fetching notifications for user: $userId');

        try {
          return firestore
              .collection(collection)
              .where('recipient_id', isEqualTo: userId)
              .orderBy('created_at', descending: true)
              .snapshots()
              .map((snapshot) {
                print('Received ${snapshot.docs.length} notifications');
                return snapshot.docs
                    .map(
                      (doc) => notification_model.UserNotification.fromJson(
                        Map<String, dynamic>.from(doc.data()),
                        doc.id,
                      ),
                    )
                    .toList();
              });
        } catch (e) {
          print('Error setting up notification stream: $e');
          return Stream.value([]);
        }
      });

  static final userRideNotificationStream =
      StreamProvider<List<RideNotification>>((ref) {
        final userId = ref.read(userProvider)?.id ?? '';
        return firestore
            .collection(rideNotificationsCollection)
            .where('recipient_id', isEqualTo: userId)
            .orderBy('created_at', descending: true)
            .orderBy(FieldPath.documentId, descending: true)
            .snapshots()
            .map(
              (snapshot) => snapshot.docs
                  .map((doc) => RideNotification.fromJson(doc.data(), doc.id))
                  .toList(),
            );
      });

  static showNotification(RemoteMessage notification) async {
    final user = await LocalStorage.getUser();
    if (user != null) {
      try {
        final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // Create a styled notification content
        final notificationStyle = BigTextStyleInformation(
          notification.notification?.body ?? '',
          htmlFormatBigText: true,
          contentTitle: notification.notification?.title ?? '',
          htmlFormatContentTitle: true,
          summaryText:
              (notification.data['type'] == 'trip_request' ||
                  notification.data['type'] == 'driver_offer')
              ? 'Tap to view trip details'
              : 'Tap to view notification',
          htmlFormatSummaryText: true,
        );

        // Create action buttons based on notification type
        final List<AndroidNotificationAction> actions = [];
        if (notification.data['type'] == 'trip_request' ||
            notification.data['type'] == 'driver_offer') {
          actions.addAll([
            AndroidNotificationAction(
              'accept_${notification.data['request_id']}',
              'Accept',
              icon: DrawableResourceAndroidBitmap('@drawable/ic_check'),
              showsUserInterface: true,
              contextual: true,
            ),
            AndroidNotificationAction(
              'reject_${notification.data['request_id']}',
              'Reject',
              icon: DrawableResourceAndroidBitmap('@drawable/ic_close'),
              showsUserInterface: true,
              contextual: true,
            ),
          ]);
        }

        final NotificationDetails notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            'ride_notifications',
            'Ride Notifications',
            channelDescription: 'Notifications for ride requests and updates',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'New ride notification',
            playSound: true,
            enableLights: true,
            color: const Color(0xFF2196F3),
            enableVibration: true,
            visibility: NotificationVisibility.public,
            styleInformation: notificationStyle,
            actions: actions,
            category: AndroidNotificationCategory.message,
            fullScreenIntent:
                notification.data['type'] == 'trip_request' ||
                notification.data['type'] == 'driver_offer',
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            interruptionLevel: InterruptionLevel.timeSensitive,
            categoryIdentifier: 'ride_notifications',
          ),
        );

        // Format notification body based on type
        String body = notification.notification?.body ?? '';
        if (notification.data['type'] == 'trip_request') {
          body =
              '''
🚗 New Trip Request

A passenger wants to join your trip:
From: ${notification.data['pickup_location']}
To: ${notification.data['dropoff_location']}
🕒 ${notification.data['trip_time']}
👥 ${notification.data['seats']} seats requested

Tap to view details''';
        } else if (notification.data['type'] == 'driver_offer') {
          body =
              '''
🚗 New Driver Offer

A driver wants to take your trip:
From: ${notification.data['pickup_location']}
To: ${notification.data['dropoff_location']}
🕒 ${notification.data['trip_time']}
💰 ${notification.data['price']} per seat

Tap to view details''';
        } else if (notification.data['type'] == 'trip_accepted') {
          body =
              '''
✅ Trip Accepted

${notification.notification?.body}
From: ${notification.data['pickup_location']}
To: ${notification.data['dropoff_location']}
🕒 ${notification.data['trip_time']}''';
        } else if (notification.data['type'] == 'trip_rejected') {
          body =
              '''
❌ Trip Rejected

${notification.notification?.body}
From: ${notification.data['pickup_location']}
To: ${notification.data['dropoff_location']}
🕒 ${notification.data['trip_time']}''';
        }

        await notificationsPlugin.show(
          id,
          notification.notification?.title,
          body,
          notificationDetails,
          payload: jsonEncode(notification.data),
        );

        // Set up notification action handler
        notificationsPlugin.initialize(
          const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(),
          ),
          onDidReceiveNotificationResponse:
              (NotificationResponse response) async {
                final payload = response.payload;
                if (payload != null) {
                  final data = jsonDecode(payload);
                  final actionId = response.actionId;

                  if (actionId?.startsWith('accept_') == true) {
                    final requestId = actionId!.split('_')[1];
                    if (data['type'] == 'trip_request') {
                      await OfferPoolService.acceptRideRequest(
                        requestId,
                        user.id,
                      );
                    } else if (data['type'] == 'driver_offer') {
                      await OfferPoolService.handleRideResponse(
                        requestId,
                        true,
                      );
                    }
                  } else if (actionId?.startsWith('reject_') == true) {
                    final requestId = actionId!.split('_')[1];
                    await OfferPoolService.handleRideResponse(requestId, false);
                  }

                  // Navigate to the trip details if offerpool_id exists
                  if (data['offerpool_id'] != null) {
                    if (onNotificationTapped != null) {
                      onNotificationTapped!({
                        'type': 'navigate_to_trip',
                        'offerpool_id': data['offerpool_id'],
                      });
                    }
                  }
                }
              },
        );
      } catch (e) {
        print('Error showing notification: $e');
      }
    }
  }

  static Future<String?> getToken() async {
    try {
      return await fireMessage.getToken();
    } catch (e) {
      return null;
    }
  }

  static Future<void> sendRideNotification({
    required String recipientId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String type,
  }) async {
    try {
      print('Attempting to send ride notification...');

      // Format the notification body with trip details
      final formattedBody =
          '''
${body}
From: ${data['pickup_location'] ?? 'N/A'}
To: ${data['dropoff_location'] ?? 'N/A'}
Time: ${data['trip_time'] ?? 'N/A'}
''';

      // Create the notification document in ride_notifications collection
      final notificationDoc = await firestore
          .collection(rideNotificationsCollection)
          .add({
            'recipient_id': recipientId,
            'title': title,
            'body': formattedBody,
            'data': data,
            'type': type,
            'read': false,
            'created_at': FieldValue.serverTimestamp(),
          });

      print('Created ride notification with ID: ${notificationDoc.id}');

      // Show the local notification
      final message = RemoteMessage(
        notification: RemoteNotification(title: title, body: formattedBody),
        data: {...data, 'notification_id': notificationDoc.id, 'type': type},
      );

      await showNotification(message);
      print('Local notification shown successfully');
    } catch (e) {
      print('Error sending ride notification: $e');
      rethrow;
    }
  }

  static Stream<List<RideNotification>> getRideNotifications(WidgetRef ref) {
    final user = ref.read(userProvider);

    return firestore
        .collection(rideNotificationsCollection)
        .where('recipient_id', isEqualTo: user?.id)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return RideNotification.fromJson(doc.data(), doc.id);
          }).toList();
        });
  }

  static Future<void> markRideNotificationAsRead(String notificationId) async {
    try {
      await firestore
          .collection(rideNotificationsCollection)
          .doc(notificationId)
          .update({'is_read': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  static Future<void> deleteRideNotification(String notificationId) async {
    try {
      await firestore
          .collection(rideNotificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    try {
      await firestore.collection('notifications').doc(notificationId).update({
        'is_read': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  static Stream<List<Map<String, dynamic>>> getNotifications(WidgetRef ref) {
    final user = ref.read(userProvider);

    return firestore
        .collection('notifications')
        .where('recipient_id', isEqualTo: user?.id)
        .orderBy('created_at', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
        });
  }
}

