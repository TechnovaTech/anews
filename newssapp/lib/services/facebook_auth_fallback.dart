// Fallback Facebook service for when the main package has issues
class FacebookAuthService {
  static Future<FacebookUser?> signIn() async {
    try {
      print('🔵 Facebook login attempted (fallback mode)');
      // Return null to indicate Facebook login is not available
      return null;
    } catch (e) {
      print('🔴 Facebook sign-in error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    print('🔵 Facebook logout (fallback mode)');
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