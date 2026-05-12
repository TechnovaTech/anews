import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://visoniq.info/api';
  static const String baseServerUrl = 'https://visoniq.info';

  // Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
    }
  }

  // Get current user profile
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  // Sign Up
  static Future<Map<String, dynamic>> signUp(String name, String email, String password, String state) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password, 'state': state, 'role': 'user'}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Sign up failed');
    }
  }

  // Get all news
  static Future<List<dynamic>> getNews({String? categoryId, String? language, String? userState}) async {
    String url = '$baseUrl/news';
    List<String> params = [];
    if (categoryId != null && categoryId.isNotEmpty) {
      params.add('category=$categoryId');
    }
    if (language != null && language.isNotEmpty) {
      params.add('language=$language');
    }
    if (userState != null && userState.isNotEmpty) {
      params.add('userState=$userState');
    }
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['news'] ?? [];
    } else {
      throw Exception('Failed to load news');
    }
  }

  // Get all reels
  static Future<List<dynamic>> getReels({String? categoryId, String? language}) async {
    String url = '$baseUrl/reels';
    List<String> params = [];
    if (categoryId != null && categoryId.isNotEmpty) {
      params.add('category=$categoryId');
    }
    if (language != null && language.isNotEmpty) {
      params.add('language=${language.toUpperCase()}');
    }
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }
    print('Fetching reels from: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Reels response: $data');
      return data['reels'] ?? [];
    } else {
      throw Exception('Failed to load reels');
    }
  }

  // Get all stories
  static Future<List<dynamic>> getStories() async {
    final response = await http.get(Uri.parse('$baseUrl/stories'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['stories'] ?? [];
    } else {
      throw Exception('Failed to load stories');
    }
  }

  // Get all categories
  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['categories'] ?? [];
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // Update user preferences
  static Future<Map<String, dynamic>> updateUserPreferences(String userId, String language, List<String> categoryIds) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'preferences': {
          'language': language,
          'categories': categoryIds,
        }
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update preferences');
    }
  }

  // Get rewards
  static Future<List<dynamic>> getRewards() async {
    final response = await http.get(Uri.parse('$baseUrl/rewards'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['rewards'] ?? [];
    } else {
      throw Exception('Failed to load rewards');
    }
  }

  // Award points for saving content
  static Future<void> awardPoints(String userId, int points) async {
    final response = await http.put(
      Uri.parse('$baseUrl/wallet/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'action': 'increase', 'amount': points}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to award points');
    }
  }

  // Like a reel
  static Future<int> likeReel(String reelId) async {
    final response = await http.post(Uri.parse('$baseUrl/reels/$reelId/like'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['likes'] ?? 0;
    }
    throw Exception('Failed to like reel');
  }

  // Unlike a reel
  static Future<int> unlikeReel(String reelId) async {
    final response = await http.delete(Uri.parse('$baseUrl/reels/$reelId/like'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['likes'] ?? 0;
    }
    throw Exception('Failed to unlike reel');
  }

  // Save a reel
  static Future<int> saveReel(String reelId) async {
    final response = await http.post(Uri.parse('$baseUrl/reels/$reelId/save'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['saves'] ?? 0;
    }
    return 0;
  }

  // Unsave a reel
  static Future<int> unsaveReel(String reelId) async {
    final response = await http.delete(Uri.parse('$baseUrl/reels/$reelId/save'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['saves'] ?? 0;
    }
    return 0;
  }

  // Get notifications for user
  static Future<List<dynamic>> getNotifications(String language) async {
    final response = await http.get(Uri.parse('$baseUrl/notifications?language=$language'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['notifications'] ?? [];
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUserProfile(String userId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update user profile: ${response.body}');
    }
  }

  // Google Sign-In
  static Future<Map<String, dynamic>> googleSignIn(String email, String name, String googleId, String state) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/google-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'name': name,
        'googleId': googleId,
        'state': state,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Google sign-in failed: ${response.body}');
    }
  }

  // Google Sign-In with new/existing user detection
  static Future<Map<String, dynamic>> googleSignInWithStatus(String email, String name, String googleId, String state) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/google-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'name': name,
        'googleId': googleId,
        'state': state,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      data['isNew'] = response.statusCode == 201;
      return data;
    } else {
      throw Exception('Google sign-in failed: ${response.body}');
    }
  }

  // Facebook Sign-In
  static Future<Map<String, dynamic>> facebookSignIn(String email, String name, String facebookId, String state) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/facebook-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'name': name,
        'facebookId': facebookId,
        'state': state,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Facebook sign-in failed: ${response.body}');
    }
  }
}
