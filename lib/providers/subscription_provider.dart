import 'package:flutter/material.dart';
import '../models/subscription_dto.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  SubscriptionDTO? _subscription;
  bool _isLoading = false;
  String? _error;

  SubscriptionDTO? get subscription => _subscription;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  bool get hasActiveSubscription => _subscription != null && _subscription!.isActive;

  Future<void> checkSubscription(String companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _subscription = await _subscriptionService.getByCompany(companyId);
    } catch (e) {
      _error = e.toString();
      print('Error checking subscription: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
