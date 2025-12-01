import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:ryde_rw/models/request_model.dart';
import 'package:ryde_rw/service/notification_service.dart';
import 'package:intl/intl.dart';

class MessengerService {
  static Future<void> acceptedLifuti(
    RequestRide passenger,
    BuildContext context,
  ) async {
    
    await NotificationService.sendNotification({
      'user_id': passenger.requestedBy,
      'title': "Confirm", //locale.confirmationlufiti,
      'body': "Confirm description", //locale.confirmationdescription,
      'isRead': false,
      'data': {'lifuti_id': passenger.id},
      'createdAt': Timestamp.now(),
    });
  }

  static Future<void> lifutiRejected(
    RequestRide passenger,
    BuildContext context,
  ) async {
    
    await NotificationService.sendNotification({
      'user_id': passenger.requestedBy,
      'title': "Rejected", //locale.rejectedlifuti,
      'body': "Rejected description", // locale.rejectedlifutidescription,
      'isRead': false,
      'data': {'lifuti_id': passenger.id},
      'createdAt': Timestamp.now(),
    });
  }

  static Future<void> lifutiCancelled(
    RequestRide passenger,
    BuildContext context,
  ) async {
    
    await NotificationService.sendNotification({
      'recipient_id': passenger.rider,
      'title': "Cancel", //ledlifuti,
      'body':
          '''
🚫 Trip Cancelled

The passenger has cancelled the trip.
From: ${passenger.pickupLocation.address}
To: ${passenger.dropoffLocation.address}
Time: ${DateFormat('MMM dd, yyyy HH:mm').format(passenger.requestedTime.toDate())}
''',
      'isRead': false,
      'data': {
        'lifuti_id': passenger.rider,
        'type': 'trip_cancelled',
        'request_id': passenger.id,
        'cancelled_by': passenger.requestedBy,
        'pickup_location': passenger.pickupLocation.address,
        'dropoff_location': passenger.dropoffLocation.address,
        'trip_time': passenger.requestedTime.toDate().toString(),
      },
      'createdAt': Timestamp.now(),
    });
  }

  static Future<void> sendTripRequestNotification(RequestRide request) async {
    await NotificationService.sendNotification({
      'recipient_id': request.rider,
      'title': 'New Trip Request',
      'body':
          '''
🚗 New Trip Request

A passenger wants to join your trip:
From: ${request.pickupLocation.address}
To: ${request.dropoffLocation.address}
🕒 ${DateFormat('MMM dd, yyyy HH:mm').format(request.requestedTime.toDate())}
👥 ${request.seats} seats requested

Tap to view details''',
      'isRead': false,
      'data': {
        'type': 'trip_request',
        'request_id': request.id,
        'passenger_id': request.requestedBy,
        'pickup_location': request.pickupLocation.address,
        'dropoff_location': request.dropoffLocation.address,
        'trip_time': request.requestedTime.toDate().toString(),
        'seats': request.seats,
        'price': request.price,
        'action_required': true,
      },
      'createdAt': Timestamp.now(),
    });
  }

  static Future<void> sendDriverOfferNotification(RequestRide request) async {
    await NotificationService.sendNotification({
      'recipient_id': request.requestedBy,
      'title': 'New Driver Offer',
      'body':
          '''
🚗 New Driver Offer

A driver wants to take your trip:
From: ${request.pickupLocation.address}
To: ${request.dropoffLocation.address}
🕒 ${DateFormat('MMM dd, yyyy HH:mm').format(request.requestedTime.toDate())}
💰 ${request.price} per seat

Tap to view details''',
      'isRead': false,
      'data': {
        'type': 'driver_offer',
        'request_id': request.id,
        'driver_id': request.rider,
        'pickup_location': request.pickupLocation.address,
        'dropoff_location': request.dropoffLocation.address,
        'trip_time': request.requestedTime.toDate().toString(),
        'price': request.price,
        'action_required': true,
      },
      'createdAt': Timestamp.now(),
    });
  }

  // static Future<void> orderServed(UserOrder order, BuildContext context) async {
  //   
  //   await NotificationService.sendNotification({
  //     'user_id': order.user,
  //     'title': locale.orderStatusUpdated,
  //     'body': locale.orderServed(order.orderId),
  //     'isRead': false,
  //     'data': {
  //       'order_id': order.id,
  //     },
  //     'createdAt': Timestamp.now(),
  //   });
  // }
}

