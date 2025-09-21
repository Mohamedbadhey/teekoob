import 'package:teekoob/core/services/network_service.dart';

class SubscriptionService {
  final NetworkService _networkService;

  SubscriptionService() : _networkService = NetworkService() {
    _networkService.initialize();
  }

  // Get available subscription plans
  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    try {
      // Note: No local storage - always fetch from API

      // If not available locally, try to fetch from server
      try {
        final response = await _networkService.get('/subscriptions/plans');
        if (response.statusCode == 200) {
          final plans = List<Map<String, dynamic>>.from(response.data['plans']);
          
          // Note: No local storage - plans not saved locally
          
          return plans;
        }
      } catch (e) {
        print('Failed to fetch subscription plans from server: $e');
      }

      // Return default plans if all else fails
      return _getDefaultPlans();
    } catch (e) {
      return _getDefaultPlans();
    }
  }

  // Get user's current subscription
  Future<Map<String, dynamic>?> getCurrentSubscription(String userId) async {
    try {
      // First try to get from local storage
      // Note: No local storage - return null
      final localSubscription = null;
      if (localSubscription != null) {
        return localSubscription;
      }

      // If not available locally, try to fetch from server
      try {
        final response = await _networkService.get('/subscriptions/user/$userId');
        if (response.statusCode == 200) {
          final subscription = response.data['subscription'];
          
          // Save to local storage
          // Note: No local storage - subscription not saved locally
          
          return subscription;
        }
      } catch (e) {
        print('Failed to fetch user subscription from server: $e');
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Create a new subscription
  Future<Map<String, dynamic>> createSubscription({
    required String userId,
    required String planId,
    required String paymentMethodId,
  }) async {
    try {
      final response = await _networkService.post('/subscriptions/create', data: {
        'userId': userId,
        'planId': planId,
        'paymentMethodId': paymentMethodId,
      });

      if (response.statusCode == 200) {
        final subscription = response.data['subscription'];
        
        // Save to local storage
        // Note: No local storage - subscription not saved locally
        
        return subscription;
      } else {
        throw Exception('Failed to create subscription: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to create subscription: $e');
    }
  }

  // Cancel subscription
  Future<void> cancelSubscription(String userId, String subscriptionId) async {
    try {
      final response = await _networkService.post('/subscriptions/cancel', data: {
        'userId': userId,
        'subscriptionId': subscriptionId,
      });

      if (response.statusCode == 200) {
        // Update local storage
        // Note: No local storage - return null
        final currentSubscription = null;
        if (currentSubscription != null) {
          currentSubscription['status'] = 'cancelled';
          currentSubscription['cancelledAt'] = DateTime.now().toIso8601String();
          // Note: No local storage - subscription not saved locally
        }
      } else {
        throw Exception('Failed to cancel subscription: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  // Reactivate subscription
  Future<void> reactivateSubscription(String userId, String subscriptionId) async {
    try {
      final response = await _networkService.post('/subscriptions/reactivate', data: {
        'userId': userId,
        'subscriptionId': subscriptionId,
      });

      if (response.statusCode == 200) {
        // Update local storage
        // Note: No local storage - return null
        final currentSubscription = null;
        if (currentSubscription != null) {
          currentSubscription['status'] = 'active';
          currentSubscription['reactivatedAt'] = DateTime.now().toIso8601String();
          // Note: No local storage - subscription not saved locally
        }
      } else {
        throw Exception('Failed to reactivate subscription: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to reactivate subscription: $e');
    }
  }

  // Update payment method
  Future<void> updatePaymentMethod(String userId, String subscriptionId, String newPaymentMethodId) async {
    try {
      final response = await _networkService.put('/subscriptions/payment-method', data: {
        'userId': userId,
        'subscriptionId': subscriptionId,
        'paymentMethodId': newPaymentMethodId,
      });

      if (response.statusCode == 200) {
        // Update local storage
        // Note: No local storage - return null
        final currentSubscription = null;
        if (currentSubscription != null) {
          currentSubscription['paymentMethodId'] = newPaymentMethodId;
          currentSubscription['updatedAt'] = DateTime.now().toIso8601String();
          // Note: No local storage - subscription not saved locally
        }
      } else {
        throw Exception('Failed to update payment method: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to update payment method: $e');
    }
  }

  // Get payment methods
  Future<List<Map<String, dynamic>>> getPaymentMethods(String userId) async {
    try {
      // First try to get from local storage
      // Note: No local storage - return empty list
      final localPaymentMethods = <Map<String, dynamic>>[];
      if (localPaymentMethods.isNotEmpty) {
        return localPaymentMethods;
      }

      // If not available locally, try to fetch from server
      try {
        final response = await _networkService.get('/users/$userId/payment-methods');
        if (response.statusCode == 200) {
          final paymentMethods = List<Map<String, dynamic>>.from(response.data['paymentMethods']);
          
          // Save to local storage
          // Note: No local storage - payment methods not saved locally
          
          return paymentMethods;
        }
      } catch (e) {
        print('Failed to fetch payment methods from server: $e');
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Add payment method
  Future<Map<String, dynamic>> addPaymentMethod(String userId, Map<String, dynamic> paymentMethod) async {
    try {
      final response = await _networkService.post('/users/$userId/payment-methods', data: paymentMethod);

      if (response.statusCode == 200) {
        final newPaymentMethod = response.data['paymentMethod'];
        
        // Add to local storage
        // Note: No local storage - return empty list
        final currentPaymentMethods = <Map<String, dynamic>>[];
        currentPaymentMethods.add(newPaymentMethod);
        // Note: No local storage - payment methods not saved locally
        
        return newPaymentMethod;
      } else {
        throw Exception('Failed to add payment method: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to add payment method: $e');
    }
  }

  // Remove payment method
  Future<void> removePaymentMethod(String userId, String paymentMethodId) async {
    try {
      final response = await _networkService.delete('/users/$userId/payment-methods/$paymentMethodId');

      if (response.statusCode == 200) {
        // Remove from local storage
        // Note: No local storage - return empty list
        final currentPaymentMethods = <Map<String, dynamic>>[];
        currentPaymentMethods.removeWhere((method) => method['id'] == paymentMethodId);
        // Note: No local storage - payment methods not saved locally
      } else {
        throw Exception('Failed to remove payment method: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to remove payment method: $e');
    }
  }

  // Get billing history
  Future<List<Map<String, dynamic>>> getBillingHistory(String userId) async {
    try {
      // First try to get from local storage
      // Note: No local storage - return empty list
      final localBillingHistory = <Map<String, dynamic>>[];
      if (localBillingHistory.isNotEmpty) {
        return localBillingHistory;
      }

      // If not available locally, try to fetch from server
      try {
        final response = await _networkService.get('/users/$userId/billing-history');
        if (response.statusCode == 200) {
          final billingHistory = List<Map<String, dynamic>>.from(response.data['billingHistory']);
          
          // Save to local storage
          // Note: No local storage - billing history not saved locally
          
          return billingHistory;
        }
      } catch (e) {
        print('Failed to fetch billing history from server: $e');
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Apply coupon code
  Future<Map<String, dynamic>> applyCoupon(String userId, String couponCode) async {
    try {
      final response = await _networkService.post('/subscriptions/apply-coupon', data: {
        'userId': userId,
        'couponCode': couponCode,
      });

      if (response.statusCode == 200) {
        return response.data['coupon'];
      } else {
        throw Exception('Failed to apply coupon: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to apply coupon: $e');
    }
  }

  // Get subscription features
  Future<List<Map<String, dynamic>>> getSubscriptionFeatures(String planId) async {
    try {
      // First try to get from local storage
      // Note: No local storage - return empty list
      final localFeatures = <Map<String, dynamic>>[];
      if (localFeatures.isNotEmpty) {
        return localFeatures;
      }

      // If not available locally, try to fetch from server
      try {
        final response = await _networkService.get('/subscriptions/plans/$planId/features');
        if (response.statusCode == 200) {
          final features = List<Map<String, dynamic>>.from(response.data['features']);
          
          // Save to local storage
          // Note: No local storage - features not saved locally
          
          return features;
        }
      } catch (e) {
        print('Failed to fetch subscription features from server: $e');
      }

      // Return default features if all else fails
      return _getDefaultFeatures(planId);
    } catch (e) {
      return _getDefaultFeatures(planId);
    }
  }

  // Check if user has access to a feature
  Future<bool> hasFeatureAccess(String userId, String featureKey) async {
    try {
      final subscription = await getCurrentSubscription(userId);
      if (subscription == null) return false;

      final planId = subscription['planId'];
      final features = await getSubscriptionFeatures(planId);
      
      return features.any((feature) => 
        feature['key'] == featureKey && feature['enabled'] == true
      );
    } catch (e) {
      return false;
    }
  }

  // Get subscription usage statistics
  Future<Map<String, dynamic>> getSubscriptionUsage(String userId) async {
    try {
      final subscription = await getCurrentSubscription(userId);
      if (subscription == null) return {};

      final response = await _networkService.get('/subscriptions/$userId/usage');
      if (response.statusCode == 200) {
        return response.data['usage'];
      }

      return {};
    } catch (e) {
      return {};
    }
  }

  // Upgrade subscription
  Future<Map<String, dynamic>> upgradeSubscription({
    required String userId,
    required String newPlanId,
    required String paymentMethodId,
  }) async {
    try {
      final response = await _networkService.post('/subscriptions/upgrade', data: {
        'userId': userId,
        'newPlanId': newPlanId,
        'paymentMethodId': paymentMethodId,
      });

      if (response.statusCode == 200) {
        final newSubscription = response.data['subscription'];
        
        // Update local storage
        // Note: No local storage - subscription not saved locally
        
        return newSubscription;
      } else {
        throw Exception('Failed to upgrade subscription: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to upgrade subscription: $e');
    }
  }

  // Downgrade subscription
  Future<Map<String, dynamic>> downgradeSubscription({
    required String userId,
    required String newPlanId,
  }) async {
    try {
      final response = await _networkService.post('/subscriptions/downgrade', data: {
        'userId': userId,
        'newPlanId': newPlanId,
      });

      if (response.statusCode == 200) {
        final newSubscription = response.data['subscription'];
        
        // Update local storage
        // Note: No local storage - subscription not saved locally
        
        return newSubscription;
      } else {
        throw Exception('Failed to downgrade subscription: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Failed to downgrade subscription: $e');
    }
  }

  // Get default subscription plans
  List<Map<String, dynamic>> _getDefaultPlans() {
    return [
      {
        'id': 'free',
        'name': 'Free',
        'nameSomali': 'Bilaash',
        'price': 0.0,
        'currency': 'USD',
        'billingCycle': 'monthly',
        'description': 'Basic access to limited books',
        'descriptionSomali': 'Furaha buugta xadidan',
        'features': ['Limited books', 'Basic support', 'Ads'],
        'featuresSomali': ['Buugta xadidan', 'Taageero aasaasi ah', 'Dhaqdhaqaaqa'],
        'maxBooks': 5,
        'maxAudioBooks': 2,
        'offlineAccess': false,
        'prioritySupport': false,
        'isPopular': false,
        'isRecommended': false,
      },
      {
        'id': 'premium',
        'name': 'Premium',
        'nameSomali': 'Premium',
        'price': 9.99,
        'currency': 'USD',
        'billingCycle': 'monthly',
        'description': 'Full access to all books and features',
        'descriptionSomali': 'Furaha dhammaan buugta iyo aaladaha',
        'features': ['Unlimited books', 'Premium support', 'No ads', 'Offline access'],
        'featuresSomali': ['Buugta aan xadid lahayn', 'Taageero premium ah', 'Wali dhaqdhaqaaq', 'Furaha offline'],
        'maxBooks': -1, // Unlimited
        'maxAudioBooks': -1, // Unlimited
        'offlineAccess': true,
        'prioritySupport': true,
        'isPopular': true,
        'isRecommended': true,
      },
      {
        'id': 'lifetime',
        'name': 'Lifetime',
        'nameSomali': 'Nolol dhammeystiran',
        'price': 199.99,
        'currency': 'USD',
        'billingCycle': 'one-time',
        'description': 'One-time payment for lifetime access',
        'descriptionSomali': 'Lacag hal mar ah oo furaha nolol dhammeystiran',
        'features': ['Lifetime access', 'All features', 'Priority support', 'Early access'],
        'featuresSomali': ['Furaha nolol dhammeystiran', 'Dhammaan aaladaha', 'Taageero aasaasi ah', 'Furaha hore'],
        'maxBooks': -1, // Unlimited
        'maxAudioBooks': -1, // Unlimited
        'offlineAccess': true,
        'prioritySupport': true,
        'isPopular': false,
        'isRecommended': false,
      },
    ];
  }

  // Get default features for a plan
  List<Map<String, dynamic>> _getDefaultFeatures(String planId) {
    switch (planId) {
      case 'free':
        return [
          {'key': 'basic_books', 'name': 'Basic Books', 'enabled': true},
          {'key': 'basic_support', 'name': 'Basic Support', 'enabled': true},
          {'key': 'ads', 'name': 'Advertisements', 'enabled': true},
          {'key': 'offline_access', 'name': 'Offline Access', 'enabled': false},
          {'key': 'priority_support', 'name': 'Priority Support', 'enabled': false},
        ];
      case 'premium':
        return [
          {'key': 'unlimited_books', 'name': 'Unlimited Books', 'enabled': true},
          {'key': 'premium_support', 'name': 'Premium Support', 'enabled': true},
          {'key': 'no_ads', 'name': 'No Advertisements', 'enabled': true},
          {'key': 'offline_access', 'name': 'Offline Access', 'enabled': true},
          {'key': 'priority_support', 'name': 'Priority Support', 'enabled': true},
        ];
      case 'lifetime':
        return [
          {'key': 'lifetime_access', 'name': 'Lifetime Access', 'enabled': true},
          {'key': 'all_features', 'name': 'All Features', 'enabled': true},
          {'key': 'priority_support', 'name': 'Priority Support', 'enabled': true},
          {'key': 'early_access', 'name': 'Early Access', 'enabled': true},
          {'key': 'exclusive_content', 'name': 'Exclusive Content', 'enabled': true},
        ];
      default:
        return [];
    }
  }
}
