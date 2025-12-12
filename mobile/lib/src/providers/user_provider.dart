import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService api;
  UserModel? currentUser;
  bool isLoading = false;
  String? error;

  UserProvider(this.api);

  Future<bool> loginUser(String phone, String pin) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final session = await api.loginUser(phone, pin);
      currentUser = session.user;
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      currentUser = null;
      if (kDebugMode) {
        print('loginUser error: $e');
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerUser(UserModel userData, String pin) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      currentUser = await api.registerUser(userData, pin);
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      currentUser = null;
      if (kDebugMode) {
        print('registerUser error: $e');
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMpesaBalance(double balance) async {
    if (currentUser == null) return false;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await api.updateMpesaBalance(currentUser!.phone, balance);
      // Update local user data
      currentUser = currentUser!.copyWith(mpesaBalance: balance);
      error = null;
      return true;
    } catch (e) {
      error = e.toString();
      if (kDebugMode) {
        print('updateMpesaBalance error: $e');
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    currentUser = null;
    error = null;
    notifyListeners();
  }
}
