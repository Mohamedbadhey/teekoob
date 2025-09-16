import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:teekoob/features/subscription/services/subscription_service.dart';

// Events
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubscriptionPlans extends SubscriptionEvent {
  const LoadSubscriptionPlans();
}

class LoadCurrentSubscription extends SubscriptionEvent {
  final String userId;

  const LoadCurrentSubscription(this.userId);

  @override
  List<Object> get props => [userId];
}

class CreateSubscription extends SubscriptionEvent {
  final String userId;
  final String planId;
  final String paymentMethodId;

  const CreateSubscription({
    required this.userId,
    required this.planId,
    required this.paymentMethodId,
  });

  @override
  List<Object> get props => [userId, planId, paymentMethodId];
}

class CancelSubscription extends SubscriptionEvent {
  final String userId;
  final String subscriptionId;

  const CancelSubscription(this.userId, this.subscriptionId);

  @override
  List<Object> get props => [userId, subscriptionId];
}

class ReactivateSubscription extends SubscriptionEvent {
  final String userId;
  final String subscriptionId;

  const ReactivateSubscription(this.userId, this.subscriptionId);

  @override
  List<Object> get props => [userId, subscriptionId];
}

class UpdatePaymentMethod extends SubscriptionEvent {
  final String userId;
  final String subscriptionId;
  final String newPaymentMethodId;

  const UpdatePaymentMethod({
    required this.userId,
    required this.subscriptionId,
    required this.newPaymentMethodId,
  });

  @override
  List<Object> get props => [userId, subscriptionId, newPaymentMethodId];
}

class LoadPaymentMethods extends SubscriptionEvent {
  final String userId;

  const LoadPaymentMethods(this.userId);

  @override
  List<Object> get props => [userId];
}

class AddPaymentMethod extends SubscriptionEvent {
  final String userId;
  final Map<String, dynamic> paymentMethod;

  const AddPaymentMethod(this.userId, this.paymentMethod);

  @override
  List<Object> get props => [userId, paymentMethod];
}

class RemovePaymentMethod extends SubscriptionEvent {
  final String userId;
  final String paymentMethodId;

  const RemovePaymentMethod(this.userId, this.paymentMethodId);

  @override
  List<Object> get props => [userId, paymentMethodId];
}

class LoadBillingHistory extends SubscriptionEvent {
  final String userId;

  const LoadBillingHistory(this.userId);

  @override
  List<Object> get props => [userId];
}

class ApplyCoupon extends SubscriptionEvent {
  final String userId;
  final String couponCode;

  const ApplyCoupon(this.userId, this.couponCode);

  @override
  List<Object> get props => [userId, couponCode];
}

class LoadSubscriptionFeatures extends SubscriptionEvent {
  final String planId;

  const LoadSubscriptionFeatures(this.planId);

  @override
  List<Object> get props => [planId];
}

class CheckFeatureAccess extends SubscriptionEvent {
  final String userId;
  final String featureKey;

  const CheckFeatureAccess(this.userId, this.featureKey);

  @override
  List<Object> get props => [userId, featureKey];
}

class LoadSubscriptionUsage extends SubscriptionEvent {
  final String userId;

  const LoadSubscriptionUsage(this.userId);

  @override
  List<Object> get props => [userId];
}

class UpgradeSubscription extends SubscriptionEvent {
  final String userId;
  final String newPlanId;
  final String paymentMethodId;

  const UpgradeSubscription({
    required this.userId,
    required this.newPlanId,
    required this.paymentMethodId,
  });

  @override
  List<Object> get props => [userId, newPlanId, paymentMethodId];
}

class DowngradeSubscription extends SubscriptionEvent {
  final String userId;
  final String newPlanId;

  const DowngradeSubscription(this.userId, this.newPlanId);

  @override
  List<Object> get props => [userId, newPlanId];
}

// States
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

class SubscriptionPlansLoaded extends SubscriptionState {
  final List<Map<String, dynamic>> plans;

  const SubscriptionPlansLoaded(this.plans);

  @override
  List<Object> get props => [plans];
}

class CurrentSubscriptionLoaded extends SubscriptionState {
  final Map<String, dynamic>? subscription;

  const CurrentSubscriptionLoaded(this.subscription);

  @override
  List<Object?> get props => [subscription];
}

class PaymentMethodsLoaded extends SubscriptionState {
  final List<Map<String, dynamic>> paymentMethods;

  const PaymentMethodsLoaded(this.paymentMethods);

  @override
  List<Object> get props => [paymentMethods];
}

class BillingHistoryLoaded extends SubscriptionState {
  final List<Map<String, dynamic>> billingHistory;

  const BillingHistoryLoaded(this.billingHistory);

  @override
  List<Object> get props => [billingHistory];
}

class SubscriptionFeaturesLoaded extends SubscriptionState {
  final String planId;
  final List<Map<String, dynamic>> features;

  const SubscriptionFeaturesLoaded({
    required this.planId,
    required this.features,
  });

  @override
  List<Object> get props => [planId, features];
}

class FeatureAccessChecked extends SubscriptionState {
  final String featureKey;
  final bool hasAccess;

  const FeatureAccessChecked({
    required this.featureKey,
    required this.hasAccess,
  });

  @override
  List<Object> get props => [featureKey, hasAccess];
}

class SubscriptionUsageLoaded extends SubscriptionState {
  final Map<String, dynamic> usage;

  const SubscriptionUsageLoaded(this.usage);

  @override
  List<Object> get props => [usage];
}

class SubscriptionOperationSuccess extends SubscriptionState {
  final String message;
  final String operation;

  const SubscriptionOperationSuccess({
    required this.message,
    required this.operation,
  });

  @override
  List<Object> get props => [message, operation];
}

class CouponApplied extends SubscriptionState {
  final Map<String, dynamic> coupon;

  const CouponApplied(this.coupon);

  @override
  List<Object> get props => [coupon];
}

class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionService _subscriptionService;

  SubscriptionBloc({required SubscriptionService subscriptionService})
      : _subscriptionService = subscriptionService,
        super(const SubscriptionInitial()) {
    on<LoadSubscriptionPlans>(_onLoadSubscriptionPlans);
    on<LoadCurrentSubscription>(_onLoadCurrentSubscription);
    on<CreateSubscription>(_onCreateSubscription);
    on<CancelSubscription>(_onCancelSubscription);
    on<ReactivateSubscription>(_onReactivateSubscription);
    on<UpdatePaymentMethod>(_onUpdatePaymentMethod);
    on<LoadPaymentMethods>(_onLoadPaymentMethods);
    on<AddPaymentMethod>(_onAddPaymentMethod);
    on<RemovePaymentMethod>(_onRemovePaymentMethod);
    on<LoadBillingHistory>(_onLoadBillingHistory);
    on<ApplyCoupon>(_onApplyCoupon);
    on<LoadSubscriptionFeatures>(_onLoadSubscriptionFeatures);
    on<CheckFeatureAccess>(_onCheckFeatureAccess);
    on<LoadSubscriptionUsage>(_onLoadSubscriptionUsage);
    on<UpgradeSubscription>(_onUpgradeSubscription);
    on<DowngradeSubscription>(_onDowngradeSubscription);
  }

  Future<void> _onLoadSubscriptionPlans(
    LoadSubscriptionPlans event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(const SubscriptionLoading());

      final plans = await _subscriptionService.getSubscriptionPlans();

      emit(SubscriptionPlansLoaded(plans));
    } catch (e) {
      emit(SubscriptionError('Failed to load subscription plans: $e'));
    }
  }

  Future<void> _onLoadCurrentSubscription(
    LoadCurrentSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(const SubscriptionLoading());

      final subscription = await _subscriptionService.getCurrentSubscription(event.userId);

      emit(CurrentSubscriptionLoaded(subscription));
    } catch (e) {
      emit(SubscriptionError('Failed to load current subscription: $e'));
    }
  }

  Future<void> _onCreateSubscription(
    CreateSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(const SubscriptionLoading());

      await _subscriptionService.createSubscription(
        userId: event.userId,
        planId: event.planId,
        paymentMethodId: event.paymentMethodId,
      );

      emit(const SubscriptionOperationSuccess(
        message: 'Subscription created successfully',
        operation: 'create',
      ));

      // Reload current subscription
      add(LoadCurrentSubscription(event.userId));
    } catch (e) {
      emit(SubscriptionError('Failed to create subscription: $e'));
    }
  }

  Future<void> _onCancelSubscription(
    CancelSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      await _subscriptionService.cancelSubscription(event.userId, event.subscriptionId);

      emit(const SubscriptionOperationSuccess(
        message: 'Subscription cancelled successfully',
        operation: 'cancel',
      ));

      // Reload current subscription
      add(LoadCurrentSubscription(event.userId));
    } catch (e) {
      emit(SubscriptionError('Failed to cancel subscription: $e'));
    }
  }

  Future<void> _onReactivateSubscription(
    ReactivateSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      await _subscriptionService.reactivateSubscription(event.userId, event.subscriptionId);

      emit(const SubscriptionOperationSuccess(
        message: 'Subscription reactivated successfully',
        operation: 'reactivate',
      ));

      // Reload current subscription
      add(LoadCurrentSubscription(event.userId));
    } catch (e) {
      emit(SubscriptionError('Failed to reactivate subscription: $e'));
    }
  }

  Future<void> _onUpdatePaymentMethod(
    UpdatePaymentMethod event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      await _subscriptionService.updatePaymentMethod(
        event.userId,
        event.subscriptionId,
        event.newPaymentMethodId,
      );

      emit(const SubscriptionOperationSuccess(
        message: 'Payment method updated successfully',
        operation: 'updatePaymentMethod',
      ));

      // Reload current subscription
      add(LoadCurrentSubscription(event.userId));
    } catch (e) {
      emit(SubscriptionError('Failed to update payment method: $e'));
    }
  }

  Future<void> _onLoadPaymentMethods(
    LoadPaymentMethods event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(const SubscriptionLoading());

      final paymentMethods = await _subscriptionService.getPaymentMethods(event.userId);

      emit(PaymentMethodsLoaded(paymentMethods));
    } catch (e) {
      emit(SubscriptionError('Failed to load payment methods: $e'));
    }
  }

  Future<void> _onAddPaymentMethod(
    AddPaymentMethod event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      await _subscriptionService.addPaymentMethod(event.userId, event.paymentMethod);

      emit(const SubscriptionOperationSuccess(
        message: 'Payment method added successfully',
        operation: 'addPaymentMethod',
      ));

      // Reload payment methods
      add(LoadPaymentMethods(event.userId));
    } catch (e) {
      emit(SubscriptionError('Failed to add payment method: $e'));
    }
  }

  Future<void> _onRemovePaymentMethod(
    RemovePaymentMethod event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      await _subscriptionService.removePaymentMethod(event.userId, event.paymentMethodId);

      emit(const SubscriptionOperationSuccess(
        message: 'Payment method removed successfully',
        operation: 'removePaymentMethod',
      ));

      // Reload payment methods
      add(LoadPaymentMethods(event.userId));
    } catch (e) {
      emit(SubscriptionError('Failed to remove payment method: $e'));
    }
  }

  Future<void> _onLoadBillingHistory(
    LoadBillingHistory event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(const SubscriptionLoading());

      final billingHistory = await _subscriptionService.getBillingHistory(event.userId);

      emit(BillingHistoryLoaded(billingHistory));
    } catch (e) {
      emit(SubscriptionError('Failed to load billing history: $e'));
    }
  }

  Future<void> _onApplyCoupon(
    ApplyCoupon event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      final coupon = await _subscriptionService.applyCoupon(event.userId, event.couponCode);

      emit(CouponApplied(coupon));
    } catch (e) {
      emit(SubscriptionError('Failed to apply coupon: $e'));
    }
  }

  Future<void> _onLoadSubscriptionFeatures(
    LoadSubscriptionFeatures event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(const SubscriptionLoading());

      final features = await _subscriptionService.getSubscriptionFeatures(event.planId);

      emit(SubscriptionFeaturesLoaded(
        planId: event.planId,
        features: features,
      ));
    } catch (e) {
      emit(SubscriptionError('Failed to load subscription features: $e'));
    }
  }

  Future<void> _onCheckFeatureAccess(
    CheckFeatureAccess event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      final hasAccess = await _subscriptionService.hasFeatureAccess(
        event.userId,
        event.featureKey,
      );

      emit(FeatureAccessChecked(
        featureKey: event.featureKey,
        hasAccess: hasAccess,
      ));
    } catch (e) {
      emit(SubscriptionError('Failed to check feature access: $e'));
    }
  }

  Future<void> _onLoadSubscriptionUsage(
    LoadSubscriptionUsage event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(const SubscriptionLoading());

      final usage = await _subscriptionService.getSubscriptionUsage(event.userId);

      emit(SubscriptionUsageLoaded(usage));
    } catch (e) {
      emit(SubscriptionError('Failed to load subscription usage: $e'));
    }
  }

  Future<void> _onUpgradeSubscription(
    UpgradeSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(const SubscriptionLoading());

      await _subscriptionService.upgradeSubscription(
        userId: event.userId,
        newPlanId: event.newPlanId,
        paymentMethodId: event.paymentMethodId,
      );

      emit(const SubscriptionOperationSuccess(
        message: 'Subscription upgraded successfully',
        operation: 'upgrade',
      ));

      // Reload current subscription
      add(LoadCurrentSubscription(event.userId));
    } catch (e) {
      emit(SubscriptionError('Failed to upgrade subscription: $e'));
    }
  }

  Future<void> _onDowngradeSubscription(
    DowngradeSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(const SubscriptionLoading());

      await _subscriptionService.downgradeSubscription(
        userId: event.userId,
        newPlanId: event.newPlanId,
      );

      emit(const SubscriptionOperationSuccess(
        message: 'Subscription downgraded successfully',
        operation: 'downgrade',
      ));

      // Reload current subscription
      add(LoadCurrentSubscription(event.userId));
    } catch (e) {
      emit(SubscriptionError('Failed to downgrade subscription: $e'));
    }
  }

  // Helper methods for UI
  bool isUserSubscribed(String userId) {
    if (state is CurrentSubscriptionLoaded) {
      final currentState = state as CurrentSubscriptionLoaded;
      final subscription = currentState.subscription;
      return subscription != null && subscription['status'] == 'active';
    }
    return false;
  }

  String? getCurrentPlanId(String userId) {
    if (state is CurrentSubscriptionLoaded) {
      final currentState = state as CurrentSubscriptionLoaded;
      final subscription = currentState.subscription;
      return subscription?['planId'];
    }
    return null;
  }

  String? getCurrentPlanName(String userId) {
    if (state is CurrentSubscriptionLoaded) {
      final currentState = state as CurrentSubscriptionLoaded;
      final subscription = currentState.subscription;
      return subscription?['planName'];
    }
    return null;
  }

  DateTime? getSubscriptionExpiryDate(String userId) {
    if (state is CurrentSubscriptionLoaded) {
      final currentState = state as CurrentSubscriptionLoaded;
      final subscription = currentState.subscription;
      final expiryDate = subscription?['expiresAt'];
      if (expiryDate != null) {
        return DateTime.tryParse(expiryDate);
      }
    }
    return null;
  }

  bool isSubscriptionExpired(String userId) {
    final expiryDate = getSubscriptionExpiryDate(userId);
    if (expiryDate != null) {
      return DateTime.now().isAfter(expiryDate);
    }
    return false;
  }

  List<Map<String, dynamic>> getPopularPlans() {
    if (state is SubscriptionPlansLoaded) {
      final currentState = state as SubscriptionPlansLoaded;
      return currentState.plans.where((plan) => plan['isPopular'] == true).toList();
    }
    return [];
  }

  List<Map<String, dynamic>> getRecommendedPlans() {
    if (state is SubscriptionPlansLoaded) {
      final currentState = state as SubscriptionPlansLoaded;
      return currentState.plans.where((plan) => plan['isRecommended'] == true).toList();
    }
    return [];
  }

  Map<String, dynamic>? getPlanById(String planId) {
    if (state is SubscriptionPlansLoaded) {
      final currentState = state as SubscriptionPlansLoaded;
      try {
        return currentState.plans.firstWhere((plan) => plan['id'] == planId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  bool hasPaymentMethods(String userId) {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;
      return currentState.paymentMethods.isNotEmpty;
    }
    return false;
  }

  int getPaymentMethodsCount(String userId) {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;
      return currentState.paymentMethods.length;
    }
    return 0;
  }

  bool hasBillingHistory(String userId) {
    if (state is BillingHistoryLoaded) {
      final currentState = state as BillingHistoryLoaded;
      return currentState.billingHistory.isNotEmpty;
    }
    return false;
  }

  int getBillingHistoryCount(String userId) {
    if (state is BillingHistoryLoaded) {
      final currentState = state as BillingHistoryLoaded;
      return currentState.billingHistory.length;
    }
    return 0;
  }
}
