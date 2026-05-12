import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb ? '594850747462-r242l9u5bd3nsf8nd0gp0vrprlc1iq56.apps.googleusercontent.com' : null,
  );

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      if (kIsWeb) {
        // Web platform not configured - return null
        print('Google Sign-In not available on web - domain not authorized');
        return null;
      } else {
        // Sign out first to force account picker every time
        await _googleSignIn.signOut();
        return await _googleSignIn.signIn();
      }
    } catch (error) {
      print('Google Sign-In Error: $error');
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}