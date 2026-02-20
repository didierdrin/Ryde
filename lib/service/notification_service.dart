import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/ride_notification.dart';
import 'package:ryde_rw/service/local_storage_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/utils/contants.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/models/notification.dart' as notification_model;
import 'package:flutter/material.dart' show Color;

/// Stub payload for showing local notifications (Firebase removed).
class LocalNotificationPayload {
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  LocalNotificationPayload({this.title, this.body, this.data = const {}});
}

class NotificationService {
  static final collection = collections.notifications;
  static final rideNotificationsCollection = 'ride_notifications';
  static final notificationsPlugin = FlutterLocalNotificationsPlugin();
  static Function(Map<String, dynamic>)? onNotificationTapped;

  static Future<void> initialize() async {
    try {
      await notificationsPlugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
    } catch (e, stackTrace) {
      print('Error initializing NotificationService: $e');
      rethrow;
    }
  }

  static Future<void> sendNotification(Map<String, dynamic> data) async {
    final payload = LocalNotificationPayload(
      title: data['title']?.toString(),
      body: data['body']?.toString(),
      data: data['data'] is Map ? Map<String, dynamic>.from(data['data'] as Map) : {},
    );
    await showNotification(payload);
  }

  static Future<void> deleteAllNotifications(
    List<notification_model.UserNotification> notifications,
  ) async {}

  static Future<void> readNotifications(List<String> notificationIds) async {}

  static final userNotificationStream =
      StreamProvider<List<notification_model.UserNotification>>((ref) {
    return Stream.value([]);
  });

  static final userRideNotificationStream =
      StreamProvider<List<RideNotification>>((ref) {
    return Stream.value([]);
  });

  static Future<void> showNotification(LocalNotificationPayload notification) async {
    final user = await LocalStorage.getUser();
    if (user == null) return;
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final body = notification.body ?? '';
      final title = notification.title ?? '';
      final data = notification.data;

      final notificationStyle = BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: 'Tap to view',
        htmlFormatSummaryText: true,
      );

      final List<AndroidNotificationAction> actions = [];
      if (data['type'] == 'trip_request' || data['type'] == 'driver_offer') {
        actions.addAll([
          const AndroidNotificationAction(
            'accept',
            'Accept',
            showsUserInterface: true,
            contextual: true,
          ),
          const AndroidNotificationAction(
            'reject',
            'Reject',
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

      await notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: jsonEncode(data),
      );

      await notificationsPlugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          final payload = response.payload;
          if (payload != null) {
            try {
              final data = jsonDecode(payload) as Map<String, dynamic>;
              final actionId = response.actionId;
              if (actionId?.startsWith('accept_') == true) {
                final requestId = actionId!.split('_').skip(1).join('_');
                if (data['type'] == 'trip_request') {
                  await OfferPoolService.acceptRideRequest(requestId, user.id);
                } else if (data['type'] == 'driver_offer') {
                  await OfferPoolService.handleRideResponse(requestId, true);
                }
              } else if (actionId?.startsWith('reject_') == true) {
                final requestId = actionId!.split('_').skip(1).join('_');
                await OfferPoolService.handleRideResponse(requestId, false);
              }
              if (data['offerpool_id'] != null && onNotificationTapped != null) {
                onNotificationTapped!({
                  'type': 'navigate_to_trip',
                  'offerpool_id': data['offerpool_id'],
                });
              }
            } catch (_) {}
          }
        },
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  static Future<String?> getToken() async => null;

  static Future<void> sendRideNotification({
    required String recipientId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String type,
  }) async {
    await showNotification(LocalNotificationPayload(
      title: title,
      body: body,
      data: {...data, 'type': type},
    ));
  }

  static Stream<List<RideNotification>> getRideNotifications(WidgetRef ref) {
    return Stream.value([]);
  }

  static Future<void> markRideNotificationAsRead(String notificationId) async {}
  static Future<void> deleteRideNotification(String notificationId) async {}
  static Future<void> markAsRead(String notificationId) async {}

  static Stream<List<Map<String, dynamic>>> getNotifications(WidgetRef ref) {
    return Stream.value([]);
  }
}
