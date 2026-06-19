# Flutter App Migration Notes

## Services Using Backend API ✅

The following services should use the REST API (`lib/service/api_service.dart`):

1. **User Management** - Use `ApiService` for:
   - Registration (`ApiService.register()`)
   - Login (`ApiService.login()`)
   - Get Profile (`ApiService.getProfile()`)
   - Update Profile

2. **Trip Management** - Use `ApiService` for:
   - Request Trip (`ApiService.requestTrip()`)
   - Get My Trips (`ApiService.getMyTrips()`)
   - Get Available Trips (`ApiService.getAvailableTrips()`)
   - Accept Trip (`ApiService.acceptTrip()`)
   - Start Trip (`ApiService.startTrip()`)
   - Complete Trip (`ApiService.completeTrip()`)
   - Cancel Trip (`ApiService.cancelTrip()`)

3. **Driver Operations** - Use `ApiService` for:
   - Get Driver Profile (`ApiService.getDriverProfile()`)
   - Update Location (`ApiService.updateDriverLocation()`)
   - Toggle Availability (`ApiService.toggleDriverAvailability()`)
   - Register Vehicle (`ApiService.registerVehicle()`)

4. **Passenger Operations** - Use `ApiService` for:
   - Get Passenger Profile (`ApiService.getPassengerProfile()`)
   - Update Location (`ApiService.updatePassengerLocation()`)

5. **Payments** - Use `ApiService` for:
   - Get Payment by Trip (`ApiService.getPaymentByTrip()`)
   - Complete Payment (`ApiService.completePayment()`)

6. **Notifications (Backend)** - Use `ApiService` for:
   - Get Notifications (`ApiService.getNotifications()`)
   - Get Unread Count (`ApiService.getUnreadCount()`)
   - Mark as Read (`ApiService.markNotificationAsRead()`)
   - Mark All as Read (`ApiService.markAllNotificationsAsRead()`)

7. **Ratings** - Use `ApiService` for:
   - Create Rating (`ApiService.createRating()`)
   - Get Ratings by Trip (`ApiService.getRatingsByTrip()`)

## Services Still Using Firebase 🔥

Keep these services using Firebase:

1. **Firebase Cloud Messaging (FCM)** - `lib/service/notification_service.dart`
   - Push notifications should continue using FCM
   - The backend can send notifications via FCM tokens stored in the database

2. **Firebase Storage** - `lib/service/firebase_storage.dart`
   - File uploads (images, documents) should continue using Firebase Storage
   - Upload files to Firebase Storage, then save the URL to the backend via API

## Configuration

**API URL** is set in `lib/config/api_config.dart`.

- **Default (recommended):** production Railway — IremboPay is configured there. No extra setup needed.
- **Local backend (optional):** only if you run `ryde-backend` on your machine **and** copy all `IREMBOPAY_*` vars from Railway into `ryde-backend/.env`.

```bash
# Production backend (default — payments work)
flutter run

# Local backend on Android emulator (requires IremboPay in ryde-backend/.env)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api

# Local backend on iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

Platform notes when using a local API URL:
- Android Emulator: `http://10.0.2.2:3000/api` (not `localhost`)
- iOS Simulator: `http://localhost:3000/api`
- Physical Device: `http://YOUR_COMPUTER_IP:3000/api`

Payments use the in-app WebView (`IremboPayCheckoutScreen`) loading the backend hosted checkout page at `/api/payments/checkout/:invoiceNumber`. The mobile app does **not** need `IREMBOPAY_*` env vars — those live on the backend only.

## Example: Updating UserService

Instead of:
```dart
UserService.getUser(phone)
```

Use:
```dart
final response = await ApiService.getProfile();
// Map response to User model
```

## Example: Updating RequestRideService

Instead of:
```dart
RequestRideService.createRequestRide(requestRide)
```

Use:
```dart
final tripData = {
  'pickupLatitude': requestRide.pickupLocation.latitude,
  'pickupLongitude': requestRide.pickupLocation.longitude,
  'pickupAddress': requestRide.pickupLocation.address,
  'destinationLatitude': requestRide.dropoffLocation.latitude,
  'destinationLongitude': requestRide.dropoffLocation.longitude,
  'destinationAddress': requestRide.dropoffLocation.address,
  'distance': calculatedDistance,
  'fare': requestRide.price,
};
await ApiService.requestTrip(tripData);
```

## Example: File Upload with Firebase Storage + Backend

```dart
// 1. Upload file to Firebase Storage
final fileUrl = await FirebaseStorageService.uploadImage(file, 'profile_images');

// 2. Save URL to backend via API
await ApiService.updateProfile({'profilePicture': fileUrl});
```

## Migration Checklist

- [ ] Confirm `lib/config/api_config.dart` uses production URL (default) or `--dart-define=API_BASE_URL` for local dev
- [ ] Replace `UserService` calls with `ApiService` calls
- [ ] Replace `RequestRideService` calls with `ApiService` calls
- [ ] Replace `DriverService` calls with `ApiService` calls
- [ ] Replace `VehicleService` calls with `ApiService` calls
- [ ] Keep `NotificationService` using FCM for push notifications
- [ ] Keep `FirebaseStorageService` for file uploads
- [ ] Update all screens that use Firebase services to use API instead
- [ ] Test authentication flow
- [ ] Test trip request/accept/complete flow
- [ ] Test file uploads (Firebase Storage + backend API)
