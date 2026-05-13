import 'dart:convert';
import 'package:http/http.dart' as http;

class _CacheEntry {
  final String body;
  final DateTime timestamp;
  _CacheEntry(this.body, this.timestamp);
}

class ApiService {
  static const String baseUrl = 'https://visoniq.info/api';
  static const String baseServerUrl = 'https://visoniq.info';
  static const Duration _cacheTtl = Duration(minutes: 5);
  static final Map<String, _CacheEntry> _cache = {};

  static Future<String> _cachedGet(String url) async {
    final entry = _cache[url];
    if (entry != null && DateTime.now().difference(entry.timestamp) < _cacheTtl) {
      return entry.body;
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      _cache[url] = _CacheEntry(response.body, DateTime.now());
      return response.body;
    }
    throw Exception('HTTP ${response.statusCode}: $url');
  }

  static void clearCache() => _cache.clear();

  // Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
  }

  // Get current user profile
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load user profile');
  }

  // Sign Up
  static Future<Map<String, dynamic>> signUp(String name, String email, String password, String state) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password, 'state': state, 'role': 'user'}),
    );
    if (response.statusCode == 201) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['error'] ?? 'Sign up failed');
  }

  // Get news with pagination
  static Future<Map<String, dynamic>> getNewsPaged({
    String? categoryId,
    String? language,
    String? userState,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String>['page=$page', 'limit=$limit', 'status=published'];
    if (categoryId != null && categoryId.isNotEmpty) params.add('category=$categoryId');
    if (language != null && language.isNotEmpty) params.add('language=$language');
    if (userState != null && userState.isNotEmpty) params.add('userState=$userState');
    final url = '$baseUrl/news?${params.join('&')}';
    final body = await _cachedGet(url);
    final data = jsonDecode(body);
    return {
      'news': data['news'] ?? [],
      'pagination': data['pagination'] ?? {'page': page, 'pages': 1, 'total': 0},
    };
  }

  // Legacy getNews (used by breaking news, keeps existing callers working)
  static Future<List<dynamic>> getNews({String? categoryId, String? language, String? userState}) async {
    final result = await getNewsPaged(categoryId: categoryId, language: language, userState: userState, page: 1, limit: 20);
    return result['news'] as List<dynamic>;
  }

  // Get reels with pagination
  static Future<Map<String, dynamic>> getReelsPaged({
    String? categoryId,
    String? language,
    int page = 1,
    int limit = 10,
  }) async {
    final params = <String>['page=$page', 'limit=$limit'];
    if (categoryId != null && categoryId.isNotEmpty) params.add('category=$categoryId');
    if (language != null && language.isNotEmpty) params.add('language=${language.toUpperCase()}');
    final url = '$baseUrl/reels?${params.join('&')}';
    final body = await _cachedGet(url);
    final data = jsonDecode(body);
    return {
      'reels': data['reels'] ?? [],
      'pagination': data['pagination'] ?? {'page': page, 'pages': 1, 'total': 0},
    };
  }

  // Legacy getReels
  static Future<List<dynamic>> getReels({String? categoryId, String? language}) async {
    final result = await getReelsPaged(categoryId: categoryId, language: language, page: 1, limit: 10);
    return result['reels'] as List<dynamic>;
  }

  // Get all stories
  static Future<List<dynamic>> getStories() async {
    final body = await _cachedGet('$baseUrl/stories');
    return jsonDecode(body)['stories'] ?? [];
  }

  // Get all categories
  static Future<List<dynamic>> getCategories() async {
    final body = await _cachedGet('$baseUrl/categories');
    return jsonDecode(body)['categories'] ?? [];
  }

  // Update user preferences
  static Future<Map<String, dynamic>> updateUserPreferences(String userId, String language, List<String> categoryIds) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'preferences': {'language': language, 'categories': categoryIds}}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to update preferences');
  }

  // Get rewards
  static Future<List<dynamic>> getRewards() async {
    final body = await _cachedGet('$baseUrl/rewards');
    return jsonDecode(body)['rewards'] ?? [];
  }

  // Award points
  static Future<void> awardPoints(String userId, int points) async {
    final response = await http.put(
      Uri.parse('$baseUrl/wallet/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'action': 'increase', 'amount': points}),
    );
    if (response.statusCode != 200) throw Exception('Failed to award points');
  }

  // Like / unlike reel
  static Future<int> likeReel(String reelId) async {
    final response = await http.post(Uri.parse('$baseUrl/reels/$reelId/like'));
    if (response.statusCode == 200) return jsonDecode(response.body)['likes'] ?? 0;
    throw Exception('Failed to like reel');
  }

  static Future<int> unlikeReel(String reelId) async {
    final response = await http.delete(Uri.parse('$baseUrl/reels/$reelId/like'));
    if (response.statusCode == 200) return jsonDecode(response.body)['likes'] ?? 0;
    throw Exception('Failed to unlike reel');
  }

  // Save / unsave reel
  static Future<int> saveReel(String reelId) async {
    final response = await http.post(Uri.parse('$baseUrl/reels/$reelId/save'));
    if (response.statusCode == 200) return jsonDecode(response.body)['saves'] ?? 0;
    return 0;
  }

  static Future<int> unsaveReel(String reelId) async {
    final response = await http.delete(Uri.parse('$baseUrl/reels/$reelId/save'));
    if (response.statusCode == 200) return jsonDecode(response.body)['saves'] ?? 0;
    return 0;
  }

  // Get notifications
  static Future<List<dynamic>> getNotifications(String language) async {
    final body = await _cachedGet('$baseUrl/notifications?language=$language');
    return jsonDecode(body)['notifications'] ?? [];
  }

  // Get active ads (cached)
  static Future<List<dynamic>> getAds() async {
    try {
      final body = await _cachedGet('$baseUrl/ads?status=active');
      return jsonDecode(body)['ads'] ?? [];
    } catch (_) {
      return [];
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUserProfile(String userId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to update user profile: ${response.body}');
  }

  // Google Sign-In
  static Future<Map<String, dynamic>> googleSignIn(String email, String name, String googleId, String state) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/google-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'name': name, 'googleId': googleId, 'state': state}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Google sign-in failed: ${response.body}');
  }

  static Future<Map<String, dynamic>> googleSignInWithStatus(String email, String name, String googleId, String state) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/google-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'name': name, 'googleId': googleId, 'state': state}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      data['isNew'] = response.statusCode == 201;
      return data;
    }
    throw Exception('Google sign-in failed: ${response.body}');
  }

  // Facebook Sign-In
  static Future<Map<String, dynamic>> facebookSignIn(String email, String name, String facebookId, String state) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/facebook-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'name': name, 'facebookId': facebookId, 'state': state}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) return jsonDecode(response.body);
    throw Exception('Facebook sign-in failed: ${response.body}');
  }
}
