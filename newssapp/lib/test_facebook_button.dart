import 'package:flutter/material.dart';
import 'services/facebook_auth_service.dart';

class TestFacebookButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        print('🔵 Testing Facebook login...');
        final user = await FacebookAuthService.signIn();
        if (user != null) {
          print('✅ Success: ${user.name} - ${user.email}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Success: ${user.name}')),
          );
        } else {
          print('❌ Facebook login failed');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Facebook login failed')),
          );
        }
      },
      child: Text('Test Facebook Login'),
    );
  }
}