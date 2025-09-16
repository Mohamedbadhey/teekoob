import 'package:hive_flutter/hive_flutter.dart';
import 'package:teekoob/core/models/user_model.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:teekoob/core/models/category_model.dart';

class StorageService {
  static const String _userBoxName = 'userBox';
  static const String _booksBoxName = 'booksBox';
  static const String _categoriesBoxName = 'categoriesBox';
  static const String _libraryBoxName = 'libraryBox';
  static const String _settingsBoxName = 'settingsBox';
  static const String _downloadsBoxName = 'downloadsBox';

  late Box<User> _userBox;
  late Box<Book> _booksBox;
  late Box<Category> _categoriesBox;
  late Box<dynamic> _libraryBox;
  late Box<dynamic> _settingsBox;
  late Box<dynamic> _downloadsBox;
  
  bool _isInitialized = false;

  // Initialize storage service
  Future<void> initialize() async {
    try {
      print('🚀 StorageService: Starting initialization...');
      
      // Register adapters
      Hive.registerAdapter(UserAdapter());
      Hive.registerAdapter(BookAdapter());
      Hive.registerAdapter(CategoryAdapter());
      print('📝 StorageService: Adapters registered');
      
      // Open boxes
      _userBox = await Hive.openBox<User>(_userBoxName);
      _booksBox = await Hive.openBox<Book>(_booksBoxName);
      _categoriesBox = await Hive.openBox<Category>(_categoriesBoxName);
      _libraryBox = await Hive.openBox(_libraryBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);
      _downloadsBox = await Hive.openBox(_downloadsBoxName);
      print('📦 StorageService: All boxes opened successfully');
      
      _isInitialized = true;
      print('✅ StorageService: Initialization completed');
    } catch (e) {
      print('❌ StorageService: Initialization failed: $e');
      rethrow;
    }
  }

  // User operations
  Future<void> saveUser(User user) async {
    await _userBox.put('currentUser', user);
  }

  User? getUser() {
    return _userBox.get('currentUser');
  }

  Future<void> deleteUser() async {
    await _userBox.clear();
  }

  // Books operations
  Future<void> saveBook(Book book) async {
    await _booksBox.put(book.id, book);
  }

  Future<void> saveBooks(List<Book> books) async {
    final Map<String, Book> bookMap = {
      for (var book in books) book.id: book
    };
    await _booksBox.putAll(bookMap);
  }

  Book? getBook(String bookId) {
    if (!_isInitialized) {
      print('⚠️ StorageService: Not initialized, cannot get book: $bookId');
      return null;
    }
    
    try {
      final book = _booksBox.get(bookId);
      print('📖 StorageService: Retrieved book: $bookId - ${book != null ? 'found' : 'not found'}');
      return book;
    } catch (e) {
      print('❌ StorageService: Error getting book: $e');
      return null;
    }
  }

  List<Book> getBooks() {
    return _booksBox.values.toList();
  }

  Future<void> deleteBook(String bookId) async {
    await _booksBox.delete(bookId);
  }

  Future<void> clearBooks() async {
    await _booksBox.clear();
  }

  // Categories operations
  Future<void> saveCategory(Category category) async {
    await _categoriesBox.put(category.id, category);
  }

  Future<void> saveCategories(List<Category> categories) async {
    final Map<String, Category> categoryMap = {
      for (var category in categories) category.id: category
    };
    await _categoriesBox.putAll(categoryMap);
  }

  Category? getCategory(String categoryId) {
    return _categoriesBox.get(categoryId);
  }

  List<Category> getCategories() {
    return _categoriesBox.values.toList();
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoriesBox.delete(categoryId);
  }

  Future<void> clearCategories() async {
    await _categoriesBox.clear();
  }

  // Library operations
  Future<void> saveLibraryItem(String userId, String bookId, Map<String, dynamic> item) async {
    if (!_isInitialized) {
      print('⚠️ StorageService: Not initialized, cannot save library item');
      throw Exception('StorageService not initialized');
    }
    
    try {
      final key = '${userId}_$bookId';
      await _libraryBox.put(key, item);
      print('💾 StorageService: Saved library item for user: $userId, book: $bookId');
    } catch (e) {
      print('❌ StorageService: Error saving library item: $e');
      throw Exception('Failed to save library item: $e');
    }
  }

  Map<String, dynamic>? getLibraryItem(String userId, String bookId) {
    if (!_isInitialized) {
      print('⚠️ StorageService: Not initialized, cannot get library item');
      return null;
    }
    
    try {
      final key = '${userId}_$bookId';
      final item = _libraryBox.get(key);
      print('📖 StorageService: Retrieved library item for user: $userId, book: $bookId - ${item != null ? 'found' : 'not found'}');
      
      // Convert LinkedMap to Map<String, dynamic> if needed
      if (item != null) {
        if (item is Map<String, dynamic>) {
          return item;
        } else if (item is Map) {
          return Map<String, dynamic>.from(item);
        }
      }
      
      return null;
    } catch (e) {
      print('❌ StorageService: Error getting library item: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> getLibraryItems(String userId) {
    if (!_isInitialized) {
      print('⚠️ StorageService: Not initialized, cannot get library items');
      return [];
    }
    
    try {
      final items = _libraryBox.values
          .where((item) => item is Map && (item as Map)['userId'] == userId)
          .map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          })
          .toList();
      print('📚 StorageService: Retrieved ${items.length} library items for user: $userId');
      return items;
    } catch (e) {
      print('❌ StorageService: Error getting library items: $e');
      return [];
    }
  }

  Future<void> deleteLibraryItem(String userId, String bookId) async {
    final key = '${userId}_$bookId';
    await _libraryBox.delete(key);
  }

  // Settings operations
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> deleteSetting(String key) async {
    await _settingsBox.delete(key);
  }

  // Downloads operations
  Future<void> saveDownload(String bookId, Map<String, dynamic> downloadInfo) async {
    await _downloadsBox.put(bookId, downloadInfo);
  }

  Map<String, dynamic>? getDownload(String bookId) {
    return _downloadsBox.get(bookId);
  }

  List<Map<String, dynamic>> getDownloads() {
    return _downloadsBox.values
        .where((item) => item is Map<String, dynamic>)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<void> deleteDownload(String bookId) async {
    await _downloadsBox.delete(bookId);
  }

  // Cleanup
  Future<void> close() async {
    await _userBox.close();
    await _booksBox.close();
    await _categoriesBox.close();
    await _libraryBox.close();
    await _settingsBox.close();
    await _downloadsBox.close();
  }

  // Settings management
  Map<String, dynamic> getSettings(String userId) {
    try {
      final settings = _settingsBox.get(userId);
      if (settings != null) {
        return Map<String, dynamic>.from(settings);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<void> saveSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await _settingsBox.put(userId, settings);
    } catch (e) {
      print('Failed to save settings: $e');
    }
  }

  // Cache management
  Future<void> clearCache() async {
    try {
      await _booksBox.clear();
      await _downloadsBox.clear();
    } catch (e) {
      print('Failed to clear cache: $e');
    }
  }

  // Subscription management
  List<Map<String, dynamic>> getSubscriptionPlans() {
    try {
      final plans = _settingsBox.get('subscription_plans');
      if (plans != null) {
        return List<Map<String, dynamic>>.from(plans);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> saveSubscriptionPlans(List<Map<String, dynamic>> plans) async {
    try {
      await _settingsBox.put('subscription_plans', plans);
    } catch (e) {
      print('Failed to save subscription plans: $e');
    }
  }

  Map<String, dynamic>? getUserSubscription(String userId) {
    try {
      final subscription = _settingsBox.get('subscription_$userId');
      if (subscription != null) {
        return Map<String, dynamic>.from(subscription);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUserSubscription(String userId, Map<String, dynamic> subscription) async {
    try {
      await _settingsBox.put('subscription_$userId', subscription);
    } catch (e) {
      print('Failed to save user subscription: $e');
    }
  }

  List<Map<String, dynamic>> getUserPaymentMethods(String userId) {
    try {
      final paymentMethods = _settingsBox.get('payment_methods_$userId');
      if (paymentMethods != null) {
        return List<Map<String, dynamic>>.from(paymentMethods);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> saveUserPaymentMethods(String userId, List<Map<String, dynamic>> paymentMethods) async {
    try {
      await _settingsBox.put('payment_methods_$userId', paymentMethods);
    } catch (e) {
      print('Failed to save user payment methods: $e');
    }
  }

  List<Map<String, dynamic>> getUserBillingHistory(String userId) {
    try {
      final billingHistory = _settingsBox.get('billing_history_$userId');
      if (billingHistory != null) {
        return List<Map<String, dynamic>>.from(billingHistory);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> saveUserBillingHistory(String userId, List<Map<String, dynamic>> billingHistory) async {
    try {
      await _settingsBox.put('billing_history_$userId', billingHistory);
    } catch (e) {
      print('Failed to save user billing history: $e');
    }
  }

  List<Map<String, dynamic>> getSubscriptionFeatures(String planId) {
    try {
      final features = _settingsBox.get('subscription_features_$planId');
      if (features != null) {
        return List<Map<String, dynamic>>.from(features);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> saveSubscriptionFeatures(String planId, List<Map<String, dynamic>> features) async {
    try {
      await _settingsBox.put('subscription_features_$planId', features);
    } catch (e) {
      print('Failed to save subscription features: $e');
    }
  }
}
