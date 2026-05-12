import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookTestScreen extends StatefulWidget {
  const FacebookTestScreen({super.key});

  @override
  State<FacebookTestScreen> createState() => _FacebookTestScreenState();
}

class _FacebookTestScreenState extends State<FacebookTestScreen> {
  String _status = 'Ready to test';
  Map<String, dynamic>? _userData;

  Future<void> _testFacebookLogin() async {
    setState(() {
      _status = 'Testing Facebook login...';
      _userData = null;
    });

    try {
      print('🔵 Starting Facebook test...');
      
      // Check SDK initialization
      try {
        final isWebInitialized = await FacebookAuth.instance.isWebSdkInitialized;
        print('🔵 Facebook Web SDK initialized: $isWebInitialized');
      } catch (e) {
        print('🔵 Facebook Web SDK check failed: $e');
      }
      
      // Check if already logged in
      final accessToken = await FacebookAuth.instance.accessToken;
      if (accessToken != null) {
        print('🔵 Already logged in, logging out first...');
        await FacebookAuth.instance.logOut();
      }

      setState(() {
        _status = 'Attempting Facebook login...';
      });

      // Attempt login with different permission sets
      LoginResult result;
      try {
        result = await FacebookAuth.instance.login(
          permissions: ['email', 'public_profile'],
        );
      } catch (e) {
        print('🔵 Login with email failed, trying basic login: $e');
        result = await FacebookAuth.instance.login(
          permissions: ['public_profile'],
        );
      }

      print('🔵 Login result: ${result.status}');
      print('🔵 Login message: ${result.message}');
      print('🔵 Access token: ${result.accessToken?.token}');

      if (result.status == LoginStatus.success) {
        print('🔵 Login successful, getting user data...');
        
        try {
          final userData = await FacebookAuth.instance.getUserData(
            fields: "name,email,picture.width(200)",
          );
          print('🔵 User data: $userData');
          
          setState(() {
            _status = 'Login successful!';
            _userData = userData;
          });
        } catch (e) {
          print('🔵 Failed to get user data: $e');
          setState(() {
            _status = 'Login successful but failed to get user data: $e';
          });
        }
      } else if (result.status == LoginStatus.cancelled) {
        setState(() {
          _status = 'Login cancelled by user';
        });
      } else if (result.status == LoginStatus.failed) {
        setState(() {
          _status = 'Login failed: ${result.message}';
        });
      } else {
        setState(() {
          _status = 'Unknown status: ${result.status}';
        });
      }
    } catch (e, stackTrace) {
      print('🔴 Facebook test error: $e');
      print('🔴 Stack trace: $stackTrace');
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facebook Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Facebook Authentication Test',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Status: $_status',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testFacebookLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Facebook Login'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FacebookAuth.instance.logOut();
                  setState(() {
                    _status = 'Logged out successfully';
                    _userData = null;
                  });
                } catch (e) {
                  setState(() {
                    _status = 'Logout error: $e';
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Logout'),
            ),
            const SizedBox(height: 20),
            if (_userData != null) ...[
              const Text(
                'User Data:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${_userData!['id'] ?? 'N/A'}'),
                    Text('Name: ${_userData!['name'] ?? 'N/A'}'),
                    Text('Email: ${_userData!['email'] ?? 'N/A'}'),
                    Text('Picture: ${_userData!['picture']?['data']?['url'] ?? 'N/A'}'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}