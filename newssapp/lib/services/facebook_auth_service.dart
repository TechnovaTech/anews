import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookAuthService {
  static Future<FacebookUser?> signIn() async {
    try {
      print('🔵 Starting Facebook login...');
      
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );
      
      print('🔵 Login status: ${result.status}');
      print('🔵 Error: ${result.message}');
      
      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        print('🔵 User data: $userData');
        
        return FacebookUser(
          id: userData['id'] ?? '',
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          picture: userData['picture']?['data']?['url'] ?? '',
        );
      }
      
      return null;
    } catch (e) {
      print('🔴 Facebook error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
      print('🔵 Facebook logout successful');
    } catch (e) {
      print('🔴 Facebook logout error: $e');
    }
  }
}

class FacebookUser {
  final String id;
  final String name;
  final String email;
  final String picture;

  FacebookUser({
    required this.id,
    required this.name,
    required this.email,
    required this.picture,
  });
}