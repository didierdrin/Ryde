import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/user.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String userKey = 'current-user';
  static const String userLocationKey = 'current-user-location';
  static const String visitKey = 'visited';
  static const String tokenKey = 'auth-token';

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  static Future<void> init(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    final savedUser = await getUser();
    if (token != null && token.isNotEmpty) {
      try {
        final profile = await ApiService.getProfile();
        final user = User.fromApiJson(profile);
        ref.read(userProvider.notifier).setUser(user);
        await setUser(user);
      } catch (_) {
        await removeToken();
        await removeUser();
        ref.read(userProvider.notifier).setUser(null);
      }
    } else if (savedUser != null) {
      ref.read(userProvider.notifier).setUser(savedUser);
    }
    final userLocation = await getUserLocation();
    if (userLocation != null && userLocation.isNotEmpty) {
      ref.read(locationProvider.notifier).setLocation(userLocation);
    }
  }

  static Future<void> setUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(user.toJSON()));
  }

  static Future<void> setUserLocation(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userLocationKey, jsonEncode(data));
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(userKey);
    if (data == null) return null;
    try {
      final map = jsonDecode(data) as Map<String, dynamic>;
      return User.fromJSON(map);
    } catch (_) {
      await removeUser();
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(userLocationKey);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      await removeUserLocation();
      return null;
    }
  }

  static Future<void> removeUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
  }

  static Future<void> removeUserLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userLocationKey);
  }

  static Future<void> setVisit({bool didVisit = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(visitKey, didVisit);
  }

  static Future<bool> getVisit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(visitKey) ?? false;
  }
}
