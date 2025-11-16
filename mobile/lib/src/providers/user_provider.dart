import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService api;
  UserModel? currentUser;
  bool isLoading = false;
  String? error;

  UserProvider(this.api);

  Future<bool> registerUser(UserModel userData) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      currentUser = await api.registerUser(userData);
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

  void logout() {
    currentUser = null;
    error = null;
    notifyListeners();
  }
}
