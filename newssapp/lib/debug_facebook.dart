import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookDebugScreen extends StatefulWidget {
  @override
  _FacebookDebugScreenState createState() => _FacebookDebugScreenState();
}

class _FacebookDebugScreenState extends State<FacebookDebugScreen> {
  String _status = 'Not logged in';
  Map<String, dynamic>? _userData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Facebook Debug')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Status: $_status'),
            SizedBox(height: 20),
            if (_userData != null) ...[
              Text('User Data:'),
              Text(_userData.toString()),
              SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed: _testFacebookLogin,
              child: Text('Test Facebook Login'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _logout,
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testFacebookLogin() async {
    try {
      setState(() => _status = 'Logging in...');
      
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData(
          fields: "name,email,picture.width(200)",
        );
        
        setState(() {
          _status = 'Login successful';
          _userData = userData;
        });
      } else {
        setState(() => _status = 'Login failed: ${result.status}');
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _logout() async {
    await FacebookAuth.instance.logOut();
    setState(() {
      _status = 'Logged out';
      _userData = null;
    });
  }
}