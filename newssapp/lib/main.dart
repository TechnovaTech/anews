import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:math' show pi;
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/api_service.dart';
import 'services/google_auth_service.dart';
import 'services/facebook_auth_service.dart';
import 'test_facebook.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'category_preferences_screen.dart';
import 'providers/language_provider.dart';

// Add missing import for SharedPreferences in ArticleDetailScreen
// (Already imported above)

String formatPublishedDate(dynamic date) {
  if (date == null) return 'Recently';
  try {
    final dt = DateTime.parse(date.toString());
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  } catch (e) {
    return 'Recently';
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Facebook SDK
  try {
    print('🔵 Initializing Facebook SDK...');
    // The SDK should auto-initialize, but let's check status
    final isInitialized = await FacebookAuth.instance.isWebSdkInitialized;
    print('🔵 Facebook SDK initialized: $isInitialized');
  } catch (e) {
    print('🔴 Facebook SDK initialization error: $e');
  }
  
  final languageProvider = LanguageProvider();
  await languageProvider.loadLanguage();
  runApp(ChangeNotifierProvider.value(
    value: languageProvider,
    child: const AsiazeApp(),
  ));
}

class AsiazeApp extends StatelessWidget {
  const AsiazeApp({super.key});

  static const Color primaryRed = Color(0xFFDC143C); // Crimson per spec

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: primaryRed),
      useMaterial3: true,
      fontFamily: null,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
    return MaterialApp(
      title: 'asiaze',
      debugShowCheckedModeBanner: false,
      theme: theme.copyWith(
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: const SplashScreen(),
      routes: {
        OnboardingScreen.routeName: (_) => const OnboardingScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        VerifyScreen.routeName: (_) => const VerifyScreen(),
        SignUpScreen.routeName: (_) => const SignUpScreen(),
        PreferencesScreen.routeName: (_) => const PreferencesScreen(),
        MainNav.routeName: (_) => const MainNav(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  void _route() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    if (!mounted) return;
    
    if (isLoggedIn) {
      // Check if user has completed preferences
      final hasPreferences = prefs.getString('language') != null && 
                            (prefs.getStringList('interests')?.isNotEmpty ?? false);
      
      if (hasPreferences) {
        Navigator.of(context).pushReplacementNamed(MainNav.routeName);
      } else {
        Navigator.of(context).pushReplacementNamed(PreferencesScreen.routeName);
      }
    } else if (seenOnboarding) {
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    } else {
      Navigator.of(context).pushReplacementNamed(OnboardingScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: AsiazeApp.primaryRed,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.translate('app_name'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lang.translate('tagline'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Onboarding ----------------
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  static const String routeName = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [
    _OnboardModel(
      title: 'Stay Updated in Seconds',
      subtitle: 'Read short 60-word news summaries instantly',
      assetName: 'refranceimages/Group (16).png',
      fallbackUrl: 'https://images.unsplash.com/photo-1587620962725-abab7fe55159?q=80&w=800&auto=format&fit=crop',
    ),
    _OnboardModel(
      title: 'News in English, Hindi & Bengali',
      subtitle: 'Read short 60-word news summaries instantly',
      assetName: 'refranceimages/8033abcf5b97cb3ea004c5f5403f403561b33094.png',
      fallbackUrl: 'https://images.unsplash.com/photo-1526378722484-bd91ca387e72?q=80&w=800&auto=format&fit=crop',
    ),
    _OnboardModel(
      title: 'Watch Short News Reels Instantly',
      subtitle: 'Scroll through quick video updates anytime',
      assetName: 'refranceimages/749bdeef4bdd026b9e097927f39b724af759225c.png',
      fallbackUrl: 'https://images.unsplash.com/photo-1611162617474-5b21f2e2d7ab?q=80&w=800&auto=format&fit=crop',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() async {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seenOnboarding', true);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(120),
                          child: Image.network(
                            p.fallbackUrl,
                            height: 220,
                            width: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) {
                              return Container(
                                height: 220,
                                width: 220,
                                color: Colors.grey[300],
                                child: Icon(Icons.image, size: 80, color: Colors.grey[600]),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9E9E9E),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pages.length,
                            (d) {
                              final isActive = d == _index;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: isActive ? 10 : 6,
                                  height: isActive ? 10 : 6,
                                  decoration: BoxDecoration(
                                    color: isActive ? red : Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: _next,
                  child: Text(_index == _pages.length - 1 ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardModel {
  final String title;
  final String subtitle;
  final String assetName;
  final String fallbackUrl;
  const _OnboardModel({
    required this.title,
    required this.subtitle,
    required this.assetName,
    required this.fallbackUrl,
  });
}

// ---------------- Login ----------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      lang.translate('app_name'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: red,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(
                        hintText: lang.translate('email_phone'),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: lang.translate('password'),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: _loading ? null : () async {
                          if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all fields')),
                            );
                            return;
                          }

                          setState(() => _loading = true);

                          try {
                            print('🔐 Attempting login with email: ${_emailCtrl.text}');
                            final loginData = await ApiService.login(
                              _emailCtrl.text,
                              _passCtrl.text,
                            );
                            print('✅ Login successful: $loginData');
                            
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('isLoggedIn', true);
                            
                            // Save user data
                            final user = loginData['user'];
                            print('Login response user data: $user');
                            
                            // Try both 'id' and '_id' fields
                            final userId = user['_id']?.toString() ?? user['id']?.toString() ?? '';
                            await prefs.setString('userId', userId);
                            await prefs.setString('userName', user['name'].toString());
                            await prefs.setString('userEmail', user['email'].toString());
                            
                            print('Saved userId: $userId');
                            
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Login successful!')),
                            );
                            
                            // For existing users, go directly to home
                            Navigator.of(context).pushReplacementNamed(MainNav.routeName);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                            );
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                        child: Text(_loading ? 'Logging in...' : lang.translate('login')),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('Or continue with', style: TextStyle(fontSize: 12)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Opening Google Sign-In...')),
                          );
                          
                          final account = await GoogleAuthService.signIn();
                          if (account != null) {
                            try {
                              final result = await ApiService.googleSignInWithStatus(
                                account.email,
                                account.displayName ?? '',
                                account.id,
                                '',
                              );
                              
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('isLoggedIn', true);
                              final user = result['user'];
                              final userId = user['_id']?.toString() ?? user['id']?.toString() ?? '';
                              await prefs.setString('userId', userId);
                              await prefs.setString('userName', user['name'].toString());
                              await prefs.setString('userEmail', user['email'].toString());
                              
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Google sign-in successful!')),
                              );
                              // isNew=true means account was just created → go to preferences
                              // isNew=false means existing user → check local prefs
                              final isNewUser = result['isNew'] == true;
                              if (isNewUser) {
                                Navigator.of(context).pushReplacementNamed(PreferencesScreen.routeName);
                              } else {
                                final hasPreferences = prefs.getString('language') != null &&
                                    (prefs.getStringList('interests')?.isNotEmpty ?? false);
                                Navigator.of(context).pushReplacementNamed(
                                  hasPreferences ? MainNav.routeName : PreferencesScreen.routeName,
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Sign-in failed: Please try again')),
                              );
                            }
                          } else {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(
                                kIsWeb ? 'Google Sign-In not available on web. Use email signup.' : 'Google sign-in cancelled or failed'
                              )),
                            );
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.g_mobiledata),
                            SizedBox(width: 8),
                            Text('Continue with Google'),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${lang.translate('dont_have_account')} "),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacementNamed(SignUpScreen.routeName);
                    },
                    child: Text(
                      lang.translate('signup'),
                      style: TextStyle(color: red, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Verify ----------------
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});
  static const String routeName = '/verify';

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _nodes = List.generate(6, (_) => FocusNode());
  final _controllers = List.generate(6, (_) => TextEditingController());

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Verify your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit code sent to your email/phone',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return SizedBox(
                        width: 44,
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _nodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 1,
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (v) {
                            if (v.isNotEmpty && i < 5) {
                              _nodes[i + 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () async {
                        final code = _code;
                        if (code == '123456') {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isLoggedIn', true);
                          await prefs.setBool('isNewUser', true); // Mark as new user
                          if (!mounted) return;
                          
                          // After verification, go to preferences for new users
                          Navigator.of(context).pushReplacementNamed(PreferencesScreen.routeName);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invalid OTP! Use 123456')),
                          );
                        }
                      },
                      child: const Text('Verify'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Didn't receive code? Resend",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- Sign Up ----------------
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  static const String routeName = '/signup';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _selectedState;
  bool _obscure = true;
  bool _loading = false;
  bool _isGoogleSignUp = false;
  bool _isFacebookSignUp = false;

  final List<String> _indianStates = [
    // States (28)
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    // Union Territories (8)
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra & Nagar Haveli and Daman & Diu',
    'Delhi (NCT of Delhi)', 'Jammu & Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'asiaze',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: red,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 8),
                    const Text('Full Name'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Full Name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Email or Phone'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Email or Phone',
                      ),
                    ),
                    if (!_isGoogleSignUp && !_isFacebookSignUp) ...[
                      const SizedBox(height: 16),
                      const Text('Password'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text('State'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      hint: const Text('Select your state'),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: _indianStates.map((state) {
                        return DropdownMenuItem(
                          value: state,
                          child: Text(state, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedState = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: _loading ? null : () async {
                          if (_isGoogleSignUp || _isFacebookSignUp) {
                            if (_selectedState == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select your state')),
                              );
                              return;
                            }

                            setState(() => _loading = true);

                            try {
                              final result = _isFacebookSignUp
                                ? await ApiService.facebookSignIn(
                                    _emailCtrl.text,
                                    _nameCtrl.text,
                                    'fb_${_emailCtrl.text}',
                                    _selectedState!,
                                  )
                                : await ApiService.googleSignIn(
                                    _emailCtrl.text,
                                    _nameCtrl.text,
                                    'google_${_emailCtrl.text}',
                                    _selectedState!,
                                  );
                              
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('isLoggedIn', true);
                              final user = result['user'];
                              await prefs.setString('userId', user['_id'].toString());
                              await prefs.setString('userName', user['name'].toString());
                              await prefs.setString('userEmail', user['email'].toString());
                              
                              if (!mounted) return;
                              Navigator.of(context).pushReplacementNamed(PreferencesScreen.routeName);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Signup failed: $e')),
                              );
                            } finally {
                              if (mounted) setState(() => _loading = false);
                            }
                          } else {
                            // Regular Sign-Up flow
                            if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty || _selectedState == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill all fields')),
                              );
                              return;
                            }

                            setState(() => _loading = true);

                            try {
                              await ApiService.signUp(
                                _nameCtrl.text,
                                _emailCtrl.text,
                                _passCtrl.text,
                                _selectedState!,
                              );
                              
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sign up successful! Verify OTP')),
                              );
                              Navigator.of(context).pushNamed(VerifyScreen.routeName);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                              );
                            } finally {
                              if (mounted) setState(() => _loading = false);
                            }
                          }
                        },
                        child: Text(_loading ? 'Signing Up...' : 'Sign Up'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('Or continue with', style: TextStyle(fontSize: 12)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: () async {
                          final account = await GoogleAuthService.signIn();
                          if (account != null) {
                            try {
                              final result = await ApiService.googleSignInWithStatus(
                                account.email,
                                account.displayName ?? '',
                                account.id,
                                '',
                              );

                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('isLoggedIn', true);
                              final user = result['user'];
                              final userId = user['_id']?.toString() ?? user['id']?.toString() ?? '';
                              await prefs.setString('userId', userId);
                              await prefs.setString('userName', user['name'].toString());
                              await prefs.setString('userEmail', user['email'].toString());

                              if (!mounted) return;
                              final isNew = result['isNew'] == true;
                              if (isNew) {
                                Navigator.of(context).pushReplacementNamed(PreferencesScreen.routeName);
                              } else {
                                final hasPreferences = prefs.getString('language') != null &&
                                    (prefs.getStringList('interests')?.isNotEmpty ?? false);
                                Navigator.of(context).pushReplacementNamed(
                                  hasPreferences ? MainNav.routeName : PreferencesScreen.routeName,
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Sign-up failed: Please try again')),
                              );
                            }
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.g_mobiledata),
                            SizedBox(width: 8),
                            Text('Continue with Google'),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(color: red, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Main Nav and app content ----------------
class MainNav extends StatefulWidget {
  const MainNav({super.key});
  static const String routeName = '/main';

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _index = 0; // default to Home

  void goHome() => setState(() => _index = 0);

  final _pages = const [
    HomeScreen(),
    VideosScreen(),
    StoryGridScreen(),
  ];

  Future<bool> _onWillPop() async {
    if (_index != 0) {
      setState(() => _index = 0);
      return false;
    }
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Exit', style: TextStyle(color: AsiazeApp.primaryRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    final lang = Provider.of<LanguageProvider>(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) SystemNavigator.pop();
      },
      child: Scaffold(
        body: _pages[_index],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 8,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          selectedItemColor: red,
          unselectedItemColor: Colors.black87,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: lang.translate('my_feed'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.videocam),
              label: lang.translate('reels'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.auto_stories),
              label: lang.translate('story'),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _query = TextEditingController();
  List<dynamic> _allPosts = [];
  List<dynamic> _results = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String _selectedCategory = '';

  void _applyFilters() {
    final q = _query.text.toLowerCase();
    setState(() {
      _results = _allPosts.where((p) {
        final title = (p['title'] ?? '').toString().toLowerCase();
        final content = (p['summary'] ?? p['content'] ?? '').toString().toLowerCase();
        final matchesQuery = q.isEmpty || title.contains(q) || content.contains(q);
        
        if (_selectedCategory.isEmpty) return matchesQuery;
        
        final catId = p['category']?['_id']?.toString() ?? '';
        return matchesQuery && catId == _selectedCategory;
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    _query.addListener(_applyFilters);
  }

  Future<void> _fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('language') ?? 'EN';
      final language = langCode == 'HIN' ? 'hindi' : (langCode == 'BEN' ? 'bengali' : 'english');
      
      // Get user's state for prioritization
      String? userState;
      try {
        final userId = prefs.getString('userId');
        if (userId != null && userId.isNotEmpty) {
          final userProfile = await ApiService.getUserProfile(userId);
          final user = userProfile['user'] ?? userProfile;
          userState = user['state'];
        }
      } catch (e) {
        print('Could not fetch user state: $e');
      }
      
      final news = await ApiService.getNews(language: language, userState: userState);
      final categories = await ApiService.getCategories();
      
      setState(() {
        _allPosts = news;
        _results = news;
        _categories = List<Map<String, dynamic>>.from(categories);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _query,
                        decoration: InputDecoration(
                          hintText: lang.translate('search'),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ChoiceChip(
                        label: Text(lang.translate('my_state')),
                        selected: _selectedCategory.isEmpty,
                        onSelected: (_) {
                          setState(() => _selectedCategory = '');
                          _applyFilters();
                        },
                        selectedColor: red,
                        labelStyle: TextStyle(color: _selectedCategory.isEmpty ? Colors.white : Colors.black),
                      ),
                    ),
                    ..._categories.map((c) {
                      final catId = c['_id']?.toString() ?? '';
                      final selected = _selectedCategory == catId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          label: Text(lang.getCategoryLabel(c)),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _selectedCategory = catId);
                            _applyFilters();
                          },
                          selectedColor: red,
                          labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isNotEmpty
                      ? ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, i) {
                            final p = _results[i];
                            final title = lang.getNewsContent(p, 'title');
                            final summary = lang.getNewsContent(p, 'summary');
                            final content = lang.getNewsContent(p, 'content');
                            final explanation = lang.getNewsContent(p, 'explanation');
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: NewsCard(
                                imageUrl: p['image'] ?? 'asset:refranceimages/Group (16).png',
                                title: title.isNotEmpty ? title : 'No Title',
                                subtitle: summary.isNotEmpty ? summary : content,
                                meta: 'ASIAZE • ${formatPublishedDate(p['publishedAt'])}',
                                allArticles: _results,
                                articleIndex: i,
                              ),
                            );
                          },
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(lang.translate('no_results'), style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userEmail = '';
  String _userState = '';
  String _initials = '';
  
  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra & Nagar Haveli and Daman & Diu',
    'Delhi (NCT of Delhi)', 'Jammu & Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _userEmail = prefs.getString('userEmail') ?? 'user@example.com';
      _initials = _getInitials(_userName);
    });
    
    // Fetch user state from backend
    if (userId != null && userId.isNotEmpty) {
      try {
        final response = await ApiService.getUserProfile(userId);
        final user = response['user'] ?? response;
        setState(() {
          _userState = user['state'] ?? 'Not specified';
        });
      } catch (e) {
        setState(() {
          _userState = 'Not specified';
        });
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  void _showStateSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Your State'),
        content: Container(
          width: double.maxFinite,
          child: DropdownButton<String>(
            value: _indianStates.contains(_userState) ? _userState : null,
            isExpanded: true,
            hint: Text('Choose your state'),
            items: _indianStates.map((state) => 
              DropdownMenuItem(
                value: state,
                child: Text(state),
              )
            ).toList(),
            onChanged: (newState) {
              Navigator.pop(context);
              if (newState != null) {
                _updateUserState(newState);
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserState(String newState) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      print('🔍 Updating state for userId: $userId to: $newState');
      
      if (userId != null && userId.isNotEmpty) {
        // Update in backend using ApiService
        final result = await ApiService.updateUserProfile(userId, {'state': newState});
        
        print('✅ API Success: $result');
        
        setState(() {
          _userState = newState;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('State updated to $newState')),
        );
      } else {
        print('❌ No userId found');
        throw Exception('User ID not found');
      }
    } catch (e) {
      print('❌ Update error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update state: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          Provider.of<LanguageProvider>(context).translate('profile'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.grey.shade300,
            child: Text(_initials, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          Center(child: Text(_userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          const SizedBox(height: 4),
          Center(child: Text(_userEmail, style: const TextStyle(color: Colors.black54))),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: Icon(Icons.card_giftcard, color: red),
            title: Text(Provider.of<LanguageProvider>(context).translate('reward')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RewardScreen()));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.bookmark, color: red),
            title: Text(Provider.of<LanguageProvider>(context).translate('saved')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavedScreen()));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.settings, color: red),
            title: Text(Provider.of<LanguageProvider>(context).translate('settings')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.location_on, color: red),
            title: Text('${Provider.of<LanguageProvider>(context).translate('your_state')} : $_userState'),
            trailing: Icon(Icons.edit, color: red),
            onTap: () => _showStateSelector(),
          ),
          const Divider(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isLoggedIn', false);
                  await prefs.remove('userId');
                  await prefs.remove('userName');
                  await prefs.remove('userEmail');
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
                },
                child: Text(Provider.of<LanguageProvider>(context).translate('logout')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VideosScreen extends StatefulWidget {
  final int startIndex;
  final String? savedReelUrl;
  const VideosScreen({super.key, this.startIndex = 0, this.savedReelUrl});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _WebVideoValue {
  final bool isInitialized;
  final Duration position;
  final Duration duration;
  const _WebVideoValue({required this.isInitialized, required this.position, required this.duration});
  _WebVideoValue copyWith({bool? isInitialized, Duration? position, Duration? duration}) =>
      _WebVideoValue(isInitialized: isInitialized ?? this.isInitialized, position: position ?? this.position, duration: duration ?? this.duration);
}

class _WebVideoController {
  final String url;
  final String viewType;
  // VideoElement removed for APK build
  final ValueNotifier<_WebVideoValue> notifier =
      ValueNotifier(const _WebVideoValue(isInitialized: false, position: Duration.zero, duration: Duration.zero));

  _WebVideoController(this.url)
      : viewType = 'web-video-' '${DateTime.now().microsecondsSinceEpoch}' '-${url.hashCode}';

  Future<void> initialize({bool muted = true, bool loop = true}) async {
    // Video initialization simplified for APK build
    notifier.value = notifier.value.copyWith(isInitialized: true, duration: Duration(milliseconds: 5000));
  }

  void play() {}
  void pause() {}
  void setMuted(bool muted) {}
  void setLooping(bool loop) {}
  void dispose() {
    // Simplified for APK build
  }
}

class _VideoModel {
  final String id;
  final String url;
  final String image;
  final String title;
  final String description;
  final String category;
  final String source;
  final String timeAgo;
  final int likes;
  final int saves;
  final int views;
  const _VideoModel({required this.id, required this.url, required this.image, required this.title, this.description = '', this.category = 'News', required this.source, required this.timeAgo, this.likes = 0, this.saves = 0, this.views = 0});
}

class _VideosScreenState extends State<VideosScreen> {
  bool _muted = true;
  late PageController _pageController;
  List<_VideoModel> _items = [];
  List<dynamic> _reelAds = [];
  final Map<int, VideoPlayerController> _controllers = {};
  bool _loading = true;
  int _currentIndex = 0;

  List<dynamic> get _feedItems {
    if (_reelAds.isEmpty) return _items;
    final List<dynamic> items = [];
    int adIndex = 0;
    for (int i = 0; i < _items.length; i++) {
      items.add(_items[i]);
      if ((i + 1) % 5 == 0 && adIndex < _reelAds.length) {
        items.add({'_isAd': true, ...(_reelAds[adIndex] as Map<String, dynamic>)});
        adIndex = (adIndex + 1) % _reelAds.length;
      }
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _pageController = PageController(initialPage: widget.startIndex);
    _fetchReels();
  }

  VideoPlayerController _buildController(int index) {
    final v = _feedItems[index] as _VideoModel;
    VideoPlayerController c;
    if (v.url.startsWith('http://') || v.url.startsWith('https://')) {
      c = VideoPlayerController.networkUrl(Uri.parse(v.url));
    } else {
      c = VideoPlayerController.asset(v.url);
    }
    c.setLooping(true);
    c.setVolume(_muted ? 0 : 1);
    return c;
  }

  Future<void> _initControllerAt(int index) async {
    final feed = _feedItems;
    if (index < 0 || index >= feed.length) return;
    if (feed[index] is! _VideoModel) return;
    if (_controllers.containsKey(index)) return;
    final c = _buildController(index);
    _controllers[index] = c;
    await c.initialize().catchError((e) => print('Video init error $index: $e'));
    if (mounted) setState(() {});
  }

  void _disposeControllersExcept(int current) {
    final keep = {current - 1, current, current + 1};
    final toRemove = _controllers.keys.where((k) => !keep.contains(k)).toList();
    for (final k in toRemove) {
      _controllers[k]?.dispose();
      _controllers.remove(k);
    }
  }

  Future<void> _loadAround(int index) async {
    _disposeControllersExcept(index);
    await _initControllerAt(index);
    _initControllerAt(index + 1);
    if (index > 0) _initControllerAt(index - 1);
    final c = _controllers[index];
    if (c != null && c.value.isInitialized) {
      c.setVolume(_muted ? 0 : 1);
      c.play();
    }
  }

  Future<void> _fetchReels() async {
    try {
      print('🎬 Fetching reels from API...');
      final prefs = await SharedPreferences.getInstance();
      final categoryIds = prefs.getStringList('categoryIds') ?? [];
      final langCode = prefs.getString('language') ?? 'EN';
      print('Language code: $langCode, Categories: $categoryIds');
      
      List<dynamic> reels;
      if (widget.savedReelUrl != null) {
        // Opened from saved — fetch all reels to find the saved one
        reels = await ApiService.getReels();
      } else if (categoryIds.isEmpty) {
        print('📡 Fetching all reels (no category filter)');
        reels = await ApiService.getReels(language: langCode);
      } else {
        print('📡 Fetching reels for categories: $categoryIds');
        reels = [];
        for (final id in categoryIds) {
          final categoryReels = await ApiService.getReels(categoryId: id, language: langCode);
          reels.addAll(categoryReels);
        }
        if (reels.isEmpty) {
          print('⚠️ No reels found for selected categories, fetching all reels');
          reels = await ApiService.getReels();
        }
      }
      print('✅ Fetched ${reels.length} reels from API');
      if (reels.isNotEmpty) {
        print('📹 First reel: ${reels[0]}');
      }

      if (reels.isEmpty) {
        if (mounted) {
          setState(() {
            _items = [];
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _items = reels.where((r) {
              final videoUrl = r['videoUrl'] ?? '';
              return videoUrl.isNotEmpty;
            }).map((r) {
              String videoUrl = r['videoUrl'] ?? '';
              String thumbnail = r['thumbnail'] ?? '';
              
              // Convert relative paths to full URLs
              if (videoUrl.startsWith('/uploads/')) {
                videoUrl = '${ApiService.baseServerUrl}/api$videoUrl';
              } else if (!videoUrl.startsWith('http://') && !videoUrl.startsWith('https://') && !videoUrl.startsWith('asset:')) {
                videoUrl = '${ApiService.baseServerUrl}/api/uploads/$videoUrl';
              }
              
              if (thumbnail.startsWith('/uploads/')) {
                thumbnail = '${ApiService.baseServerUrl}$thumbnail';
              }
              // Fix broken thumbnail (just domain with no path)
              if (thumbnail == ApiService.baseServerUrl || thumbnail == '${ApiService.baseServerUrl}/' || !thumbnail.contains('/uploads/')) {
                thumbnail = '';
              }
              
              print('📹 Video URL: $videoUrl');
              print('🖼️ Thumbnail: $thumbnail');
              
              return _VideoModel(
                id: r['_id']?.toString() ?? '',
                url: videoUrl,
                image: thumbnail,
                title: r['title'] ?? 'News Reel',
                description: r['description'] ?? '',
                category: r['category']?['name'] ?? 'News',
                source: 'ASIAZE',
                timeAgo: formatPublishedDate(r['publishedAt']),
                likes: r['likes'] ?? 0,
                saves: r['saves'] ?? 0,
                views: r['views'] ?? 0,
              );
            }).toList();
            _loading = false;
          });
        }
      }

      // Fetch reel ads
      try {
        final reelAds = await ApiService.getAds();
        if (mounted) {
          setState(() {
            _reelAds = reelAds;
          });
        }
      } catch (_) {}

      // Lazy load: only init first reel and next one
      if (mounted) {
        // If opened from saved reel, find and jump to that reel
        if (widget.savedReelUrl != null) {
          int idx = _items.indexWhere((v) => v.url == widget.savedReelUrl);
          if (idx < 0) {
            idx = _items.indexWhere((v) =>
                v.url.contains(widget.savedReelUrl!) ||
                widget.savedReelUrl!.contains(v.url.split('/').last));
          }
          if (idx >= 0) {
            _currentIndex = idx;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _pageController.hasClients) {
                _pageController.jumpToPage(idx);
                _loadAround(idx);
              }
            });
            return;
          }
        }
        _loadAround(_currentIndex);
        _loadAround(_currentIndex);
      }
    } catch (e) {
      print('Error fetching reels: $e');
      if (mounted) {
        setState(() {
          _items = [];
          _loading = false;
        });
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Recently';
    try {
      final dt = DateTime.parse(date.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _currentIndex = index;
    _loadAround(index);
    for (final entry in _controllers.entries) {
      if (entry.key != index) entry.value.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off, size: 64, color: Colors.grey.shade600),
                      const SizedBox(height: 16),
                      Text(
                        Provider.of<LanguageProvider>(context).translate('no_reels'),
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for new content',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: _feedItems.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final item = _feedItems[index];
                    if (item is! _VideoModel) {
                      return _ReelAdPage(ad: item as Map<String, dynamic>);
                    }
                    final controller = _controllers[index];
                    if (controller == null) {
                      return Container(
                        color: Colors.black,
                        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                      );
                    }
                    return _VideoPage(
                      controller: controller,
                      item: item,
                      red: red,
                      muted: _muted,
                      onToggleMute: () {
                        setState(() {
                          _muted = !_muted;
                          _controllers[index]?.setVolume(_muted ? 0 : 1);
                        });
                      },
                    );
                  },
                ),
    );
  }
}

class _VideoPage extends StatefulWidget {
  final VideoPlayerController controller;
  final _VideoModel item;
  final Color red;
  final bool muted;
  final VoidCallback onToggleMute;
  const _VideoPage({required this.controller, required this.item, required this.red, required this.muted, required this.onToggleMute});

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  bool _liked = false;
  late int _likeCount;
  bool _saved = false;
  late int _saveCount;
  bool _showDetails = false;
  String? _reelId;

  @override
  void initState() {
    super.initState();
    _reelId = widget.item.id;
    _likeCount = widget.item.likes;
    _saveCount = widget.item.saves;
    _loadPersistedState();
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final likedIds = prefs.getStringList('liked_reels') ?? [];
    final savedUrls = prefs.getStringList('saved_reel_urls') ?? [];
    final savedTitles = prefs.getStringList('saved_reel_titles') ?? [];
    final savedThumbs = prefs.getStringList('saved_reel_thumbs') ?? [];
    if (!mounted) return;
    setState(() {
      _liked = likedIds.contains(_reelId);
      _saved = savedUrls.contains(widget.item.url);
      if (_liked) _likeCount = widget.item.likes + 1;
      if (_saved) _saveCount = widget.item.saves + 1;
    });
    // Restore SavedReelsStore from prefs
    if (SavedReelsStore.saved.value.isEmpty && savedUrls.isNotEmpty) {
      final reels = <SavedReel>[];
      for (int i = 0; i < savedUrls.length; i++) {
        reels.add(SavedReel(
          url: savedUrls[i],
          title: i < savedTitles.length ? savedTitles[i] : '',
          thumbnail: i < savedThumbs.length ? savedThumbs[i] : '',
        ));
      }
      SavedReelsStore.saved.value = reels;
    }
  }

  Future<void> _toggleLike() async {
    if (_reelId == null || _reelId!.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final likedIds = List<String>.from(prefs.getStringList('liked_reels') ?? []);
    final nowLiked = !_liked;
    setState(() {
      _liked = nowLiked;
      _likeCount += nowLiked ? 1 : -1;
    });
    try {
      final newCount = nowLiked
          ? await ApiService.likeReel(_reelId!)
          : await ApiService.unlikeReel(_reelId!);
      if (mounted) setState(() => _likeCount = newCount);
    } catch (_) {}
    if (nowLiked) {
      if (!likedIds.contains(_reelId)) likedIds.add(_reelId!);
    } else {
      likedIds.remove(_reelId);
    }
    await prefs.setStringList('liked_reels', likedIds);
  }

  Future<void> _toggleSave() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrls = List<String>.from(prefs.getStringList('saved_reel_urls') ?? []);
    final savedTitles = List<String>.from(prefs.getStringList('saved_reel_titles') ?? []);
    final savedThumbs = List<String>.from(prefs.getStringList('saved_reel_thumbs') ?? []);
    setState(() => _saved = !_saved);
    final reel = SavedReel(url: widget.item.url, title: widget.item.title, thumbnail: widget.item.image);
    if (_saved) {
      savedUrls.add(widget.item.url);
      savedTitles.add(widget.item.title);
      savedThumbs.add(widget.item.image);
      SavedReelsStore.saved.value = [...SavedReelsStore.saved.value, reel];
      try {
        if (_reelId != null && _reelId!.isNotEmpty) {
          final response = await ApiService.saveReel(_reelId!);
          if (mounted) setState(() => _saveCount = response);
        }
        final userId = prefs.getString('userId');
        if (userId != null && userId.isNotEmpty) await ApiService.awardPoints(userId, 5);
      } catch (_) {}
    } else {
      final idx = savedUrls.indexOf(widget.item.url);
      if (idx >= 0) {
        savedUrls.removeAt(idx);
        if (idx < savedTitles.length) savedTitles.removeAt(idx);
        if (idx < savedThumbs.length) savedThumbs.removeAt(idx);
      }
      SavedReelsStore.saved.value = SavedReelsStore.saved.value.where((r) => r.url != widget.item.url).toList();
      try {
        if (_reelId != null && _reelId!.isNotEmpty) {
          final response = await ApiService.unsaveReel(_reelId!);
          if (mounted) setState(() => _saveCount = response);
        }
      } catch (_) {}
    }
    await prefs.setStringList('saved_reel_urls', savedUrls);
    await prefs.setStringList('saved_reel_titles', savedTitles);
    await prefs.setStringList('saved_reel_thumbs', savedThumbs);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final red = widget.red;
    final controller = widget.controller;
    final item = widget.item;

    return Stack(
      children: [
        // Video Player
        Positioned.fill(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              if (!controller.value.isInitialized) {
                return Container(color: Colors.black);
              }
              return FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              );
            },
          ),
        ),
        
        // Gradient Overlay
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black26,
                    Colors.transparent,
                    Colors.black54,
                    Colors.black87,
                  ],
                  stops: [0.0, 0.55, 0.85, 1.0],
                ),
              ),
            ),
          ),
        ),
        
        // Top header (brand centered, back left, mute right)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SizedBox(
              height: 36,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: const Text(
                      'asiaze',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          context.findAncestorStateOfType<_MainNavState>()?.goHome();
                        }
                      },
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      icon: Icon(widget.muted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                      onPressed: widget.onToggleMute,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Right side actions (vertical rail)
        Positioned(
          right: 12,
          bottom: 120,
          child: Column(
            children: [
              _CircleAction(
                icon: _liked ? Icons.favorite : Icons.favorite_border,
                label: _likeCount.toString(),
                selected: _liked,
                labelBelow: true,
                onTap: _toggleLike,
              ),
              const SizedBox(height: 20),
              _CircleAction(
                icon: _saved ? Icons.bookmark : Icons.bookmark_border,
                label: _saveCount.toString(),
                selected: _saved,
                labelBelow: true,
                onTap: _toggleSave,
              ),
              const SizedBox(height: 20),
              _CircleAction(
                icon: Icons.send,
                label: '',
                labelBelow: true,
                onTap: () async {
                  final shareText = '${item.title}\n\nWatch on asiaze: ${item.url}';
                  await Share.share(
                    shareText,
                    subject: item.title,
                  );
                },
              ),
            ],
          ),
        ),
        
        // Bottom content overlay (title, author, description)
        if (!_showDetails)
          Positioned(
            left: 16,
            right: 80,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                
                // Author and Date
                Text(
                  '${item.source.toUpperCase()} · ${item.timeAgo}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Description preview
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        
        // Video progress bar and instruction at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showDetails = !_showDetails;
              });
            },
            child: Container(
              color: Colors.black.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar
                  AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      final position = controller.value.position;
                      final duration = controller.value.duration;
                      final progress = duration.inMilliseconds > 0
                          ? position.inMilliseconds / duration.inMilliseconds
                          : 0.0;
                      
                      return Row(
                        children: [
                          Text(
                            _fmt(position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                              minHeight: 3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _fmt(duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  
                  // Instruction text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Swipe up ↑   ',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Tap to ${_showDetails ? 'close' : 'read more'} detail',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Details drawer/bottom sheet
        if (_showDetails)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    padding: const EdgeInsets.all(20),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with close button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _showDetails = false),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Title
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Author and Date
                          Text(
                            'By ${item.source} • ${item.timeAgo}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Summary/Caption heading
                          const Text(
                            'Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Full description/caption from admin panel
                          if (item.description.isNotEmpty)
                            Text(
                              item.description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.6,
                              ),
                            )
                          else
                            Text(
                              'No summary available for this reel.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          const SizedBox(height: 16),
                          
                          // Stats row
                          Row(
                            children: [
                              Icon(Icons.favorite, color: red, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '$_likeCount likes',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 20),
                              const Icon(Icons.visibility, color: Colors.white70, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${item.views} views',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------- Reel Ad Page ----------------
class _ReelAdPage extends StatelessWidget {
  final Map<String, dynamic> ad;

  const _ReelAdPage({required this.ad});

  @override
  Widget build(BuildContext context) {
    String imageUrl = ad['imageUrl']?.toString() ?? '';
    if (imageUrl.startsWith('/uploads/')) imageUrl = '${ApiService.baseServerUrl}$imageUrl';
    final title = ad['title']?.toString() ?? 'Advertisement';
    final clickUrl = ad['clickUrl']?.toString() ?? '';
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl.isNotEmpty)
          Image.network(imageUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0f0f0f)))
        else
          Container(color: const Color(0xFF0f0f0f)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.45, 1.0],
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.78),
                ],
              ),
            ),
          ),
        ),
        // Sponsored badge
        Positioned(
          top: topPad + 14,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.campaign, color: Colors.black, size: 13),
                SizedBox(width: 4),
                Text('Sponsored', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        // Bottom content
        Positioned(
          left: 16, right: 16, bottom: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, height: 1.3, shadows: [
                  Shadow(color: Colors.black54, blurRadius: 4),
                ]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              if (clickUrl.isNotEmpty)
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.tryParse(clickUrl);
                    if (uri != null && await canLaunchUrl(uri)) {
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Learn More',
                      style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool selected;
  final VoidCallback? onTap;
  final bool labelBelow;
  const _CircleAction({required this.icon, this.label, this.selected = false, this.onTap, this.labelBelow = false});

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: selected ? AsiazeApp.primaryRed.withOpacity(0.85) : Colors.white.withOpacity(0.25),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    );

    if (labelBelow) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            circle,
            if (label != null && label!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: circle,
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

// ---------------- Story Grid Screen (Instagram-like) ----------------
class StoryGridScreen extends StatefulWidget {
  const StoryGridScreen({super.key});

  @override
  State<StoryGridScreen> createState() => _StoryGridScreenState();
}

class _StoryGridScreenState extends State<StoryGridScreen> {
  Map<String, List<dynamic>> _storiesByCategory = {};
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      print('🔍 Fetching stories...');
      final stories = await ApiService.getStories();
      print('📚 Received ${stories.length} stories: $stories');
      
      final categories = await ApiService.getCategories();
      print('📂 Received ${categories.length} categories');
      
      // Group stories by category
      final Map<String, List<dynamic>> grouped = {};
      for (final story in stories) {
        final categoryId = story['category']?['_id']?.toString() ?? 'uncategorized';
        print('📖 Story: ${story['heading']} -> Category: $categoryId');
        if (!grouped.containsKey(categoryId)) {
          grouped[categoryId] = [];
        }
        grouped[categoryId]!.add(story);
      }
      
      print('🗂️ Grouped stories: $grouped');
      
      setState(() {
        _storiesByCategory = grouped;
        _categories = List<Map<String, dynamic>>.from(categories);
        _loading = false;
      });
    } catch (e) {
      print('❌ Error fetching stories: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacementNamed(MainNav.routeName),
        ),
        title: const Text(
          'Stories',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _storiesByCategory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_stories_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(lang.translate('no_stories'), style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _storiesByCategory.keys.length,
                  itemBuilder: (context, index) {
                    final categoryId = _storiesByCategory.keys.elementAt(index);
                    final categoryStories = _storiesByCategory[categoryId] ?? [];
                    
                    if (categoryStories.isEmpty) return const SizedBox.shrink();
                    
                    // Find category name or use default
                    String categoryName = 'Stories';
                    if (categoryId != 'uncategorized') {
                      final category = _categories.firstWhere(
                        (c) => c['_id']?.toString() == categoryId,
                        orElse: () => {'name': 'Stories'},
                      );
                      categoryName = lang.getCategoryLabel(category);
                    }
                        
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.8,
                              ),
                              itemCount: categoryStories.length,
                              itemBuilder: (context, storyIndex) {
                                final story = categoryStories[storyIndex];
                                
                                // Get first media item for thumbnail
                                String imageUrl = '';
                                final mediaItems = story['mediaItems'] as List<dynamic>? ?? [];
                                
                                // Find first IMAGE in mediaItems for thumbnail
                                // If no image found, use first item (video thumbnail fallback)
                                if (mediaItems.isNotEmpty) {
                                  // Try to find an image first
                                  final imageItem = mediaItems.firstWhere(
                                    (m) => m['type'] == 'image',
                                    orElse: () => mediaItems[0],
                                  );
                                  imageUrl = imageItem['url']?.toString() ?? '';
                                }
                                
                                // Fallback to story image field
                                if (imageUrl.isEmpty) {
                                  imageUrl = story['image']?.toString() ?? '';
                                }
                                
                                // Fix relative URLs
                                if (imageUrl.isNotEmpty && !imageUrl.startsWith('http') && !imageUrl.startsWith('asset:')) {
                                  imageUrl = '${ApiService.baseServerUrl}$imageUrl';
                                }
                                
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => StoryViewerScreen(
                                          stories: categoryStories,
                                          initialIndex: storyIndex,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          imageUrl.isEmpty
                                              ? Container(
                                                  color: Colors.grey.shade200,
                                                  child: Icon(Icons.image, size: 30, color: Colors.grey.shade500),
                                                )
                                              : imageUrl.startsWith('asset:')
                                                  ? Image.asset(
                                                      imageUrl.replaceFirst('asset:', ''),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stack) {
                                                        return Container(
                                                          color: Colors.grey.shade200,
                                                          child: Icon(Icons.broken_image, size: 30, color: Colors.grey.shade500),
                                                        );
                                                      },
                                                    ),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.7),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            left: 8,
                                            right: 8,
                                            child: Text(
                                              story['heading'] ?? story['title'] ?? story['storyName'] ?? 'Story',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
    );
  }
}

// ---------------- Story Viewer Screen ----------------
class StoryViewerScreen extends StatefulWidget {
  final List<dynamic> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;

  late AnimationController _progressController;
  int _currentIndex = 0;
  int _currentMediaIndex = 0;
  bool _showDetails = false;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    _startProgress();
  }

  void _startProgress() {
    _progressController.reset();
    _progressController.forward().then((_) {
      if (mounted) _nextMedia();
    });
  }

  void _nextMedia() {
    final story = widget.stories[_currentIndex];
    final mediaItems = story['mediaItems'] as List<dynamic>? ?? [];
    
    if (mediaItems.isEmpty) {
      _nextStory();
      return;
    }
    
    if (_currentMediaIndex < mediaItems.length - 1) {
      setState(() {
        _currentMediaIndex++;
        _showDetails = false;
      });
      _startProgress();
    } else {
      _nextStory();
    }
  }

  void _previousMedia() {
    if (_currentMediaIndex > 0) {
      setState(() {
        _currentMediaIndex--;
        _showDetails = false;
      });
      _startProgress();
    } else {
      _previousStory();
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _showDetails = false);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() => _showDetails = false);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          if (_showDetails) return;
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            _previousMedia();
          } else {
            _nextMedia();
          }
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _currentMediaIndex = 0;
                  _showDetails = false;
                  _liked = false;
                });

                _startProgress();
              },
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                final mediaItems = story['mediaItems'] as List<dynamic>? ?? [];
                
                // Fallback to legacy single media format
                if (mediaItems.isEmpty) {
                  final hasVideo = story['videoUrl'] != null && story['videoUrl'].toString().isNotEmpty;
                  final hasImage = story['image'] != null && story['image'].toString().isNotEmpty;
                  
                  if (hasVideo || hasImage) {
                    mediaItems.add({
                      'type': hasVideo ? 'video' : 'image',
                      'url': hasVideo ? story['videoUrl'] : story['image'],
                    });
                  }
                }
                
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    mediaItems.isEmpty
                        ? Container(
                            color: Colors.grey.shade800,
                            child: const Center(
                              child: Icon(Icons.image_not_supported, size: 80, color: Colors.white54),
                            ),
                          )
                        : IndexedStack(
                            index: _currentMediaIndex,
                            children: mediaItems.asMap().entries.map((entry) {
                              final mediaIndex = entry.key;
                              final media = entry.value;
                              String mediaUrl = media['url']?.toString() ?? '';
                              
                              print('📱 Loading media $mediaIndex: $mediaUrl');
                              
                              if (mediaUrl.startsWith('/uploads/')) {
                                mediaUrl = '${ApiService.baseServerUrl}$mediaUrl';
                              }
                              
                              print('📸 Final media URL: $mediaUrl');
                              
                              final isVideo = media['type'] == 'video';
                              
                              return mediaUrl.isEmpty
                                  ? Container(
                                      color: Colors.grey.shade800,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.image_not_supported, size: 80, color: Colors.white54),
                                            Text('Media ${mediaIndex + 1}', style: const TextStyle(color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    )
                                  : isVideo
                                      ? VideoPlayer(
                                          VideoPlayerController.networkUrl(Uri.parse(mediaUrl))
                                            ..initialize().then((_) {
                                              if (index == _currentIndex && mediaIndex == _currentMediaIndex) {
                                                VideoPlayerController.networkUrl(Uri.parse(mediaUrl)).play();
                                              }
                                            }),
                                        )
                                      : SizedBox.expand(
                                          child: Image.network(
                                            mediaUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                color: Colors.black,
                                                child: const Center(
                                                  child: CircularProgressIndicator(color: Colors.white),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              print('❌ Image load error for $mediaUrl: $error');
                                              return Container(
                                                color: Colors.grey.shade800,
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Icon(Icons.broken_image, size: 80, color: Colors.white54),
                                                      Text('Image ${mediaIndex + 1}', style: const TextStyle(color: Colors.white)),
                                                      Text('URL: $mediaUrl', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                                      const SizedBox(height: 8),
                                                      const Text('Check if server is running', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                            }).toList(),
                          ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                          stops: const [0.0, 0.3, 0.6, 1.0],
                        ),
                      ),
                    ),
                    // dots removed
                    if (!_showDetails)
                      Positioned(
                        left: 20,
                        bottom: 20,
                        child: GestureDetector(
                          onTap: () => setState(() => _showDetails = true),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Read More ↑',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!_showDetails)
                      Positioned(
                        right: 20,
                        bottom: 20,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _liked = !_liked),
                              child: Icon(
                                _liked ? Icons.favorite : Icons.favorite_border,
                                color: _liked ? Colors.red : Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () {
                                final story = widget.stories[_currentIndex];
                                Share.share(
                                  '${story['heading'] ?? story['storyName'] ?? ''}\n\n${story['description'] ?? ''}\n\nShared from Asiaze',
                                );
                              },
                              child: const Icon(Icons.ios_share, color: Colors.white, size: 28),
                            ),
                          ],
                        ),
                      ),

                  ],
                );
              },
            ),
            if (_showDetails)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      padding: const EdgeInsets.all(25),
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 24),
                                GestureDetector(
                                  onTap: () => setState(() => _showDetails = false),
                                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.stories[_currentIndex]['heading'] ?? 'Story',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.stories[_currentIndex]['description'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final story = widget.stories[_currentIndex];
                          final mediaItems = story['mediaItems'] as List<dynamic>? ?? [];
                          final totalSegments = mediaItems.isEmpty ? 1 : mediaItems.length;
                          
                          return Row(
                            children: List.generate(
                              totalSegments,
                              (index) => Expanded(
                                child: Container(
                                  height: 3,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  child: AnimatedBuilder(
                                    animation: _progressController,
                                    builder: (context, child) {
                                      double value = 0.0;
                                      if (index < _currentMediaIndex) {
                                        value = 1.0;
                                      } else if (index == _currentMediaIndex) {
                                        value = _progressController.value;
                                      }
                                      return LinearProgressIndicator(
                                        value: value,
                                        backgroundColor: Colors.white.withOpacity(0.3),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Center(
                  child: Text(
                    'asiaze',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _allCategories = [];
  bool _loading = true;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchCategories();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await ApiService.getCategories();
      if (mounted) {
        setState(() {
          _allCategories = List<Map<String, dynamic>>.from(categories);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    final lang = Provider.of<LanguageProvider>(context);
    
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final displayCategories = [
      {'name': lang.translate('breaking_news'), '_id': 'breaking_news', 'isTranslated': true, 'isBreakingNews': true},
      {'name': lang.translate('my_feed'), '_id': '', 'isTranslated': true},
      ..._allCategories,
    ];
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: Profile (left) - Logo (center) - Search (right)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Profile button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.black87, size: 24),
                    ),
                  ),
                  // Logo
                  Text(
                    'asiaze',
                    style: TextStyle(
                      color: red,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  // Search button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search, color: Colors.black87, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            // Category chips (without Stories button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayCategories.length,
                  itemBuilder: (context, index) {
                    final cat = displayCategories[index];
                    final isTranslated = cat['isTranslated'] == true;
                    final text = isTranslated ? cat['name'].toString() : lang.getCategoryLabel(cat);
                    final isActive = _currentPage == index;
                    
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? red : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive ? red : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            text,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.black87,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Swipeable category pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: displayCategories.length,
                itemBuilder: (context, index) {
                  final cat = displayCategories[index];
                  final catName = cat['name'].toString();
                  final isBreakingNews = cat['isBreakingNews'] == true;
                  
                  // Show Breaking News page or regular FeedList
                  if (isBreakingNews) {
                    return const BreakingNewsPage();
                  }
                  
                  return FeedList(
                    categoryName: catName,
                    categoryId: cat['_id']?.toString(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Breaking News Page ----------------
class BreakingNewsPage extends StatefulWidget {
  const BreakingNewsPage({super.key});

  @override
  State<BreakingNewsPage> createState() => _BreakingNewsPageState();
}

class _BreakingNewsPageState extends State<BreakingNewsPage> {
  List<dynamic> _breakingNews = [];
  List<dynamic> _reels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBreakingNews();
  }

  Future<void> _fetchBreakingNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('language') ?? 'EN';
      final language = langCode == 'HIN' ? 'hindi' : (langCode == 'BEN' ? 'bengali' : 'english');
      
      final allNews = await ApiService.getNews(language: language);
      final reels = await ApiService.getReels(language: langCode);
      
      if (mounted) {
        setState(() {
          _breakingNews = allNews.take(10).toList();
          _reels = reels.take(10).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    final lang = Provider.of<LanguageProvider>(context);
    
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breaking News Section Header
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Breaking News',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Breaking News Horizontal Scroll (like reference image)
          if (_breakingNews.isNotEmpty)
            Container(
              color: Colors.white,
              height: 280,
              padding: const EdgeInsets.only(bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _breakingNews.length,
                itemBuilder: (context, index) {
                  final article = _breakingNews[index];
                  final title = lang.getNewsContent(article, 'title');
                  final summary = lang.getNewsContent(article, 'summary');
                  final content = lang.getNewsContent(article, 'content');
                  final explanation = lang.getNewsContent(article, 'explanation');
                  final imageUrl = article['image'] ?? 'asset:refranceimages/Group (16).png';
                  final categoryName = article['category']?['name'] ?? 'News';
                  final hasVideo = article['videoUrl'] != null && article['videoUrl'].toString().isNotEmpty;
                  
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ArticlesFeedScreen(
                            articles: _breakingNews,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 320,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Background Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: imageUrl.startsWith('asset:')
                                ? Image.asset(
                                    imageUrl.replaceFirst('asset:', ''),
                                    width: 320,
                                    height: 280,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    imageUrl,
                                    width: 320,
                                    height: 280,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                          // Category badge
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                categoryName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          // Play button if video exists
                          if (hasVideo)
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow, color: Colors.black, size: 45),
                                ),
                              ),
                            ),
                          // Content at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'ASIAZE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.verified, color: Colors.blue, size: 14),
                                      const SizedBox(width: 8),
                                      Text(
                                        formatPublishedDate(article['publishedAt']),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    title.isNotEmpty ? title : 'No Title',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Recommendation Section Header
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recommendation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: red,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Recommendation List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _breakingNews.length > 5 ? 5 : _breakingNews.length,
            itemBuilder: (context, index) {
              final article = _breakingNews[index];
              final title = lang.getNewsContent(article, 'title');
              final summary = lang.getNewsContent(article, 'summary');
              final content = lang.getNewsContent(article, 'content');
              final explanation = lang.getNewsContent(article, 'explanation');
              final imageUrl = article['image'] ?? 'asset:refranceimages/Group (16).png';
              final categoryName = article['category']?['name'] ?? 'News';
              
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ArticlesFeedScreen(
                        articles: _breakingNews,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Small thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl.startsWith('asset:')
                            ? Image.asset(
                                imageUrl.replaceFirst('asset:', ''),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(width: 12),
                      // Title and category
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.isNotEmpty ? title : 'No Title',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 12,
                                color: red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Reels Section
          Container(
            width: double.infinity,
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reels',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Reels Horizontal Scroll
          if (_reels.isNotEmpty)
            Container(
              color: Colors.grey.shade100,
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _reels.length,
                itemBuilder: (context, index) {
                  final reel = _reels[index];
                  
                  // Get thumbnail URL
                  String thumbnailUrl = reel['thumbnail'] ?? '';
                  if (thumbnailUrl.isEmpty) {
                    // Try to use image field if thumbnail is not available
                    thumbnailUrl = reel['image'] ?? '';
                  }
                  
                  // Convert relative URL to absolute
                  if (thumbnailUrl.isNotEmpty && !thumbnailUrl.startsWith('http') && !thumbnailUrl.startsWith('asset:') && !thumbnailUrl.startsWith('data:')) {
                    thumbnailUrl = '${ApiService.baseServerUrl}$thumbnailUrl';
                  }
                  
                  final title = reel['title'] ?? 'Reel';
                  
                  return InkWell(
                    onTap: () {
                      // Navigate to reels screen starting at this index
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideosScreen(startIndex: index),
                        ),
                      );
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12, bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Thumbnail image
                            if (thumbnailUrl.startsWith('asset:'))
                              Image.asset(
                                thumbnailUrl.replaceFirst('asset:', ''),
                                fit: BoxFit.cover,
                              )
                            else if (thumbnailUrl.startsWith('data:image'))
                              Image.memory(
                                Uri.parse(thumbnailUrl).data!.contentAsBytes(),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade800,
                                    child: const Center(child: Icon(Icons.videocam, color: Colors.white, size: 40)),
                                  );
                                },
                              )
                            else if (thumbnailUrl.isNotEmpty)
                              Image.network(
                                thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade800,
                                    child: const Center(
                                      child: Icon(Icons.videocam, color: Colors.white, size: 40),
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey.shade800,
                                    child: const Center(
                                      child: CircularProgressIndicator(color: Colors.white),
                                    ),
                                  );
                                },
                              )
                            else
                              Container(
                                color: Colors.grey.shade800,
                                child: const Center(
                                  child: Icon(Icons.videocam, color: Colors.white, size: 40),
                                ),
                              ),
                            
                            // Gradient overlay at bottom
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            
                            // Play icon overlay
                            Center(
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Ad Video Player Widget ────────────────────────────────────────
class _AdVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const _AdVideoPlayer({required this.videoUrl});

  @override
  State<_AdVideoPlayer> createState() => _AdVideoPlayerState();
}

class _AdVideoPlayerState extends State<_AdVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
          if (!_controller.value.isPlaying)
            const Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
            ),
        ],
      ),
    );
  }
}

class FeedList extends StatefulWidget {
  final String categoryName;
  final String? categoryId;
  const FeedList({super.key, required this.categoryName, this.categoryId});

  @override
  State<FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<FeedList> {
  List<dynamic> _news = [];
  List<dynamic> _ads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('language') ?? 'EN';
      final language = langCode == 'HIN' ? 'hindi' : (langCode == 'BEN' ? 'bengali' : 'english');
      
      List<dynamic> news;
      if (widget.categoryName == 'My Feed' || widget.categoryName.contains('फ़ीड') || widget.categoryName.contains('ফিড')) {
        final categoryIds = prefs.getStringList('categoryIds') ?? [];
        if (categoryIds.isEmpty) {
          news = await ApiService.getNews(language: language);
        } else {
          news = [];
          for (final id in categoryIds) {
            final categoryNews = await ApiService.getNews(categoryId: id, language: language);
            news.addAll(categoryNews);
          }
        }
      } else {
        news = await ApiService.getNews(categoryId: widget.categoryId, language: language);
      }

      // Fetch ads for articles
      final articleAds = await ApiService.getAds();

      if (mounted) {
        setState(() {
          _news = news;
          _ads = articleAds;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Build list with ads injected every 5 items
  List<dynamic> get _feedItems {
    if (_ads.isEmpty) return _news;
    final List<dynamic> items = [];
    int adIndex = 0;
    for (int i = 0; i < _news.length; i++) {
      items.add(_news[i]);
      // Insert ad after every 5 news items
      if ((i + 1) % 5 == 0 && adIndex < _ads.length) {
        items.add({'_isAd': true, ..._ads[adIndex]});
        adIndex = (adIndex + 1) % _ads.length;
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final red = AsiazeApp.primaryRed;
    
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_news.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(lang.translate('no_news'), style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    // List layout instead of card swipe
    return ListView.builder(
      itemCount: _feedItems.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final item = _feedItems[index];

        // ── Ad card ──────────────────────────────────────────────
        if (item['_isAd'] == true) {
          String adImageUrl = item['imageUrl']?.toString() ?? '';
          if (adImageUrl.startsWith('/uploads/')) adImageUrl = '${ApiService.baseServerUrl}$adImageUrl';
          final adVideoUrl = item['videoUrl']?.toString() ?? '';
          final adClickUrl = item['clickUrl']?.toString() ?? '';
          final adTitle = item['title']?.toString() ?? 'Advertisement';
          final isVideoAd = item['adType'] == 'video' && adVideoUrl.isNotEmpty;

          return GestureDetector(
            onTap: () async {
              if (adClickUrl.isNotEmpty) {
                final uri = Uri.tryParse(adClickUrl);
                if (uri != null && await canLaunchUrl(uri)) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sponsored label
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Sponsored', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                  // Video Ad
                  if (isVideoAd)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      child: SizedBox(
                        width: double.infinity,
                        height: 200,
                        child: _AdVideoPlayer(videoUrl: adVideoUrl),
                      ),
                    )
                  // Image Ad
                  else if (adImageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      child: Image.network(
                        adImageUrl,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          color: Colors.grey.shade200,
                          child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(adTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          );
        }

        // ── News card ─────────────────────────────────────────────
        final article = item;
        final title = lang.getNewsContent(article, 'title');
        final summary = lang.getNewsContent(article, 'summary');
        final content = lang.getNewsContent(article, 'content');
        final explanation = lang.getNewsContent(article, 'explanation');
        final imageUrl = article['image'] ?? 'asset:refranceimages/Group (16).png';
        final categoryName = article['category']?['name'] ?? 'News';
        final hasVideo = article['videoUrl'] != null && article['videoUrl'].toString().isNotEmpty;
        
        return InkWell(
          onTap: () {
            final newsIndex = _news.indexOf(article);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ArticlesFeedScreen(
                  articles: _news,
                  initialIndex: newsIndex < 0 ? 0 : newsIndex,
                  ads: _ads,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail with play button
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl.startsWith('asset:')
                          ? Image.asset(
                              imageUrl.replaceFirst('asset:', ''),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              imageUrl,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                    ),
                    // Play button overlay
                    if (hasVideo)
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Title
                      Text(
                        title.isNotEmpty ? title : 'No Title',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Author and date
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 12),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'ASIAZE • ${formatPublishedDate(article['publishedAt'])}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Post {
  final String image;
  final String title;
  final String subtitle;
  final String meta;
  _Post(this.image, this.title, this.subtitle, this.meta);
}

List<_Post> _samplePosts({bool shuffle = false}) {
  // A diverse set of posts using local assets for stable testing
  final seeds = <_Post>[
    _Post(
      'asset:refranceimages/Group (16).png',
      'Thrilling Soccer Match Concludes with Dramatic Finale',
      'A match that kept fans on the edge of their seats with a nail-biting finish and standout performances.',
      'ASIAZE • 2 hours ago',
    ),
    _Post(
      'asset:refranceimages/8033abcf5b97cb3ea004c5f5403f403561b33094.png',
      'Electric Cars Gain Momentum Across Major Cities',
      'EV adoption surges as infrastructure expands, incentives rise, and range anxiety fades for urban commuters.',
      'ASIAZE • 1 hour ago',
    ),
    // Extra sample posts for testing visibility
    _Post(
      'asset:refranceimages/4f52f4f362aa7270533b2fd93039fc712e5cc169.png',
      'Health Tips: Staying Active Daily',
      'Simple routines and mindful habits keep energy up and stress low throughout your week.',
      'ASIAZE • 5 hours ago',
    ),
    _Post(
      'asset:refranceimages/Home Feed Screen - ASIAZE News App.png',
      'My State: Top Headlines Now',
      'Quick snapshot of regional updates, alerts, and stories you can glance at fast.',
      'ASIAZE • 10 minutes ago',
    ),
    _Post(
      'asset:refranceimages/749bdeef4bdd026b9e097927f39b724af759225c.png',
      'Market Update: Tech Stocks Rally Strongly',
      'Investors respond to upbeat guidance and productivity boosts from AI-led transformations across industries.',
      'ASIAZE • 30 minutes ago',
    ),
    _Post(
      'asset:refranceimages/c049d488ea53162e319b73ae144cac43efe0c895.png',
      'New AI Breakthroughs Transform Daily Life',
      'From smarter assistants to creative tools, AI continues reshaping how we work, learn, and play.',
      'ASIAZE • 3 hours ago',
    ),
    _Post(
      'asset:refranceimages/d4ef3494bb5c951553079eccc43b57d68f698bb5.png',
      'Travel Diaries: Hidden Gems Around The World',
      'Explore breathtaking locales, vibrant cultures, and offbeat trails for your next adventures.',
      'ASIAZE • 4 hours ago',
    ),
    _Post(
      'asset:refranceimages/Group (16).png',
      'Startup Spotlight: Innovating Urban Mobility',
      'Lightweight EVs, shared fleets, and smarter routing unlock new convenience in crowded metros.',
      'ASIAZE • 5 hours ago',
    ),
    _Post(
      'asset:refranceimages/8033abcf5b97cb3ea004c5f5403f403561b33094.png',
      'Health & Wellness: Simple Habits That Stick',
      'Sleep, nutrition, and micro-movement routines to boost energy throughout your day.',
      'ASIAZE • 1 day ago',
    ),
    _Post(
      'asset:refranceimages/749bdeef4bdd026b9e097927f39b724af759225c.png',
      'Finance Essentials: Building Smarter Savings Plans',
      'Tips to automate, diversify, and protect your goals in changing markets.',
      'ASIAZE • 2 days ago',
    ),
    _Post(
      'asset:refranceimages/c049d488ea53162e319b73ae144cac43efe0c895.png',
      'Entertainment Buzz: Celebrity Interview Highlights',
      'Fresh insights, surprising reveals, and behind-the-scenes stories from recent interviews.',
      'ASIAZE • 2 hours ago',
    ),
    _Post(
      'asset:refranceimages/d4ef3494bb5c951553079eccc43b57d68f698bb5.png',
      'Eco Trends: Cities Embrace Greener Architecture',
      'Smart materials and energy-efficient designs reduce carbon footprints and improve livability.',
      'ASIAZE • 6 hours ago',
    ),
  ];
  // Build a longer list for scroll testing
  final list = List<_Post>.generate(40, (i) => seeds[i % seeds.length]);
  if (shuffle) list.shuffle();
  return list;
}

// Smooth Scroll Behavior: platform-aware physics with gentle easing and page snapping support.
class _SmoothScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    final platform = Theme.of(context).platform;
    final base = (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    // Use native platform physics for lists to ensure normal scrolling.
    return base;
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notif = true;
  String _contentLang = 'EN';
  String _appLang = 'EN';

  @override
  void initState() {
    super.initState();
    _loadLanguageSettings();
  }

  Future<void> _loadLanguageSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    setState(() {
      _contentLang = lang.contentLanguageCode;
      _appLang = lang.languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(lang.translate('settings'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.article),
                    const SizedBox(width: 12),
                    Expanded(child: Text(lang.translate('content_language'))),
                    _contentChip('EN', lang),
                    const SizedBox(width: 8),
                    _contentChip('HIN', lang),
                    const SizedBox(width: 8),
                    _contentChip('BEN', lang),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.language),
                    const SizedBox(width: 12),
                    Expanded(child: Text(lang.translate('app_language'))),
                    _appChip('EN', lang),
                    const SizedBox(width: 8),
                    _appChip('HIN', lang),
                    const SizedBox(width: 8),
                    _appChip('BEN', lang),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoryPreferencesScreen()),
              );
            },
            child: ListTile(
              leading: Icon(Icons.list, color: red),
              title: Text(lang.translate('category_preferences')),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
          SwitchListTile(
            value: _notif,
            onChanged: (v) => setState(() => _notif = v),
            title: Text(lang.translate('notifications')),
            secondary: const Icon(Icons.notifications),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: Text(lang.translate('privacy_policy')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(lang.translate('terms_conditions')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(lang.translate('about_us')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutUsScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),

    );
  }

  Widget _contentChip(String value, LanguageProvider lang) {
    final selected = _contentLang == value;
    return ChoiceChip(
      label: Text(value),
      selected: selected,
      onSelected: (_) async {
        setState(() => _contentLang = value);
        await lang.setContentLanguage(value);
        
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');
        if (userId != null && userId.isNotEmpty) {
          final categoryIds = prefs.getStringList('categoryIds') ?? [];
          try {
            await ApiService.updateUserPreferences(userId, value, categoryIds);
          } catch (e) {
            print('Failed to update content language: $e');
          }
        }
      },
      selectedColor: AsiazeApp.primaryRed,
      labelStyle: TextStyle(color: selected ? Colors.white : null),
    );
  }

  Widget _appChip(String value, LanguageProvider lang) {
    final selected = _appLang == value;
    return ChoiceChip(
      label: Text(value),
      selected: selected,
      onSelected: (_) async {
        setState(() => _appLang = value);
        await lang.setLanguage(value);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('appLanguage', value);
      },
      selectedColor: AsiazeApp.primaryRed,
      labelStyle: TextStyle(color: selected ? Colors.white : null),
    );
  }
}

String _truncateWords(String text, int maxChars) {
  final cleaned = text.trim();
  if (cleaned.length <= maxChars) return cleaned;
  return '${cleaned.substring(0, maxChars).trim()}...';
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Policy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: red)),
            const SizedBox(height: 4),
            Text('Last updated: January 2025', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            _section('1. Information We Collect',
                'We collect information you provide when registering, such as your name, email address, phone number, and state. We also collect usage data including articles read, reels watched, and preferences selected.'),
            _section('2. How We Use Your Information',
                'We use your information to personalize your news feed, deliver content in your preferred language, send notifications about breaking news, and improve our services.'),
            _section('3. Data Storage',
                'Your data is stored securely on our servers. We do not sell your personal information to third parties.'),
            _section('4. Third-Party Services',
                'We use Google Sign-In for authentication. Please refer to Google\'s Privacy Policy for information on how they handle your data.'),
            _section('5. Cookies & Local Storage',
                'The app stores your preferences locally on your device including language settings, category preferences, and login state.'),
            _section('6. Your Rights',
                'You may request deletion of your account and associated data at any time by contacting us at support@asiaze.cloud.'),
            _section('7. Changes to This Policy',
                'We may update this Privacy Policy from time to time. We will notify you of any changes by updating the date at the top of this page.'),
            _section('8. Contact Us',
                'If you have any questions about this Privacy Policy, please contact us at:\n\nsupport@asiaze.cloud\nwww.asiaze.cloud'),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF444444))),
        ],
      ),
    );
  }
}

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Terms & Conditions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: red)),
            const SizedBox(height: 4),
            Text('Last updated: January 2025', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            _section('1. Acceptance of Terms',
                'By downloading and using the ASIAZE app, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the app.'),
            _section('2. Use of the App',
                'ASIAZE is a news platform providing short news summaries, reels, and stories. You agree to use the app only for lawful purposes and in a manner that does not infringe the rights of others.'),
            _section('3. User Accounts',
                'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account.'),
            _section('4. Content',
                'All news content, reels, and stories published on ASIAZE are the property of ASIAZE or its content partners. You may not reproduce, distribute, or create derivative works without permission.'),
            _section('5. Reward Points',
                'Reward points earned through the app have no monetary value and cannot be exchanged for cash. ASIAZE reserves the right to modify or terminate the rewards program at any time.'),
            _section('6. Disclaimer',
                'ASIAZE provides news content for informational purposes only. We do not guarantee the accuracy, completeness, or timeliness of any content.'),
            _section('7. Limitation of Liability',
                'ASIAZE shall not be liable for any indirect, incidental, or consequential damages arising from your use of the app.'),
            _section('8. Governing Law',
                'These Terms shall be governed by the laws of India. Any disputes shall be subject to the exclusive jurisdiction of courts in India.'),
            _section('9. Contact',
                'For any questions regarding these Terms, contact us at:\n\nsupport@asiaze.cloud\nwww.asiaze.cloud'),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF444444))),
        ],
      ),
    );
  }
}

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('About Us', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text('asiaze', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: red, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text('Your World, Simplified', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            _section('Who We Are',
                'ASIAZE is a modern news platform designed for the fast-paced world. We deliver short, crisp 60-word news summaries so you stay informed without spending hours reading.'),
            _section('Our Mission',
                'To make quality news accessible to everyone in their preferred language — English, Hindi, and Bengali — through an engaging and easy-to-use mobile experience.'),
            _section('What We Offer',
                '• Short news summaries\n• News Reels — short video updates\n• Stories — visual news cards\n• Multilingual content (EN / HIN / BEN)\n• Personalized feed based on your interests\n• State-wise news prioritization'),
            _section('Reward Program',
                'Earn points by engaging with content — saving articles and reels. Redeem your points for exciting rewards through our wallet system.'),
            _section('Contact Us',
                'We\'d love to hear from you!\n\nEmail: support@asiaze.cloud\nWebsite: www.asiaze.cloud'),
            const SizedBox(height: 10),
            Center(
              child: Text('Version 1.0.0', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF444444))),
        ],
      ),
    );
  }
}

// Saved Articles data and page
class SavedArticle {
  final String image;
  final String title;
  final String subtitle;
  final String meta;
  const SavedArticle({required this.image, required this.title, required this.subtitle, required this.meta});
}

class SavedArticlesStore {
  static final ValueNotifier<List<SavedArticle>> saved = ValueNotifier<List<SavedArticle>>([]);
  static bool isSavedTitle(String title) => saved.value.any((e) => e.title == title);
  static void toggle(SavedArticle a) async {
    final list = List<SavedArticle>.from(saved.value);
    final idx = list.indexWhere((e) => e.title == a.title);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.insert(0, a);
      // Award points for saving
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');
        if (userId != null && userId.isNotEmpty) {
          await ApiService.awardPoints(userId, 5);
        }
      } catch (e) {
        print('Failed to award points: $e');
      }
    }
    saved.value = list;
  }
}

// Combined Saved Screen with tabs
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()),
          title: Text(Provider.of<LanguageProvider>(context).translate('saved')),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          bottom: TabBar(
            labelColor: red,
            unselectedLabelColor: Colors.black54,
            indicatorColor: red,
            tabs: [
              Tab(text: Provider.of<LanguageProvider>(context).translate('articles')),
              Tab(text: Provider.of<LanguageProvider>(context).translate('reels')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SavedArticlesTab(),
            SavedReelsTab(),
          ],
        ),
      ),
    );
  }
}

class SavedReel {
  final String url;
  final String title;
  final String thumbnail;
  const SavedReel({required this.url, required this.title, required this.thumbnail});
}

class SavedReelsStore {
  static final ValueNotifier<List<SavedReel>> saved = ValueNotifier<List<SavedReel>>([]);
  static bool isSavedUrl(String url) => saved.value.any((e) => e.url == url);
  static void toggle(SavedReel r) async {
    final list = List<SavedReel>.from(saved.value);
    final idx = list.indexWhere((e) => e.url == r.url);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.insert(0, r);
      // Award points for saving
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');
        if (userId != null && userId.isNotEmpty) {
          await ApiService.awardPoints(userId, 5);
        }
      } catch (e) {
        print('Failed to award points: $e');
      }
    }
    saved.value = list;
  }
}

class _SavedReelPlayerScreen extends StatefulWidget {
  final SavedReel reel;
  const _SavedReelPlayerScreen({required this.reel});

  @override
  State<_SavedReelPlayerScreen> createState() => _SavedReelPlayerScreenState();
}

class _SavedReelPlayerScreenState extends State<_SavedReelPlayerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.reel.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
          _controller.setLooping(true);
        }
      }).catchError((e) => print('Saved reel play error: $e'));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _initialized
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _controller.value.isPlaying ? _controller.pause() : _controller.play();
                    });
                  },
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                )
              : const Center(child: CircularProgressIndicator(color: Colors.white)),
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          if (_initialized)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Text(
                widget.reel.title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class SavedReelsTab extends StatefulWidget {
  const SavedReelsTab({super.key});
  @override
  State<SavedReelsTab> createState() => _SavedReelsTabState();
}

class _SavedReelsTabState extends State<SavedReelsTab> {
  @override
  void initState() {
    super.initState();
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final urls = prefs.getStringList('saved_reel_urls') ?? [];
    final titles = prefs.getStringList('saved_reel_titles') ?? [];
    final thumbs = prefs.getStringList('saved_reel_thumbs') ?? [];
    if (urls.isNotEmpty && SavedReelsStore.saved.value.isEmpty) {
      SavedReelsStore.saved.value = List.generate(urls.length, (i) => SavedReel(
        url: urls[i],
        title: i < titles.length ? titles[i] : '',
        thumbnail: i < thumbs.length ? thumbs[i] : '',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    return ValueListenableBuilder<List<SavedReel>>(
      valueListenable: SavedReelsStore.saved,
      builder: (context, list, _) {
        if (list.isEmpty) {
          final lang = Provider.of<LanguageProvider>(context);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(lang.translate('no_saved_reels'), style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                Text('Save reels by tapping the bookmark icon.', style: TextStyle(color: Colors.black45)),
              ],
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final r = list[i];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VideosScreen(savedReelUrl: r.url),
                  ),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: r.thumbnail.isNotEmpty
                        ? Image.network(
                            r.thumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade800,
                              child: const Icon(Icons.videocam, color: Colors.white, size: 40),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.videocam, color: Colors.white, size: 40),
                          ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                        ),
                      ),
                    ),
                  ),
                  const Center(child: Icon(Icons.play_circle_outline, size: 48, color: Colors.white70)),
                  Positioned(
                    bottom: 8, left: 8, right: 40,
                    child: Text(
                      r.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        SavedReelsStore.saved.value = SavedReelsStore.saved.value.where((s) => s.url != r.url).toList();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setStringList('saved_reel_urls', SavedReelsStore.saved.value.map((s) => s.url).toList());
                        await prefs.setStringList('saved_reel_titles', SavedReelsStore.saved.value.map((s) => s.title).toList());
                        await prefs.setStringList('saved_reel_thumbs', SavedReelsStore.saved.value.map((s) => s.thumbnail).toList());
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: red, shape: BoxShape.circle),
                        child: const Icon(Icons.bookmark, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class SavedArticlesTab extends StatelessWidget {
  const SavedArticlesTab({super.key});

  Widget _imageWidget(String image) {
    if (image.startsWith('asset:')) {
      return Image.asset(image.replaceFirst('asset:', ''), height: 160, width: double.infinity, fit: BoxFit.cover);
    } else if (image.startsWith('refranceimages/')) {
      return Image.asset(image, height: 160, width: double.infinity, fit: BoxFit.cover);
    } else {
      return Image.network(image, height: 160, width: double.infinity, fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SavedArticle>>(
      valueListenable: SavedArticlesStore.saved,
      builder: (context, list, _) {
          if (list.isEmpty) {
            final lang = Provider.of<LanguageProvider>(context);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    lang.translate('no_saved_articles'),
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save articles by tapping the bookmark icon.',
                    style: TextStyle(color: Colors.black45, fontSize: 14),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final a = list[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  elevation: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _imageWidget(a.image),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(a.subtitle, style: TextStyle(color: Colors.grey.shade700)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(a.meta, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.bookmark, color: Colors.black87),
                                  onPressed: () {
                                    SavedArticlesStore.toggle(a);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
  }
}

class NewsCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String meta;
  final List<dynamic> allArticles;
  final int articleIndex;

  const NewsCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.allArticles,
    required this.articleIndex,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArticlesFeedScreen(
              articles: allArticles,
              initialIndex: articleIndex,
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: SizedBox(
          height: screenHeight * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 60,
                child: imageUrl.startsWith('asset:')
                    ? Image.asset(imageUrl.replaceFirst('asset:', ''), fit: BoxFit.cover, width: double.infinity)
                    : Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity,
                        errorBuilder: (_, __, ___) => Image.asset('refranceimages/Group (16).png', fit: BoxFit.cover)),
              ),
              Expanded(
                flex: 40,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Expanded(child: Text(subtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis)),
                      const SizedBox(height: 4),
                      Text(meta, style: TextStyle(color: Colors.grey.shade500, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Articles Feed Screen (vertical 3D scroll) ----------------
class ArticlesFeedScreen extends StatefulWidget {
  final List<dynamic> articles;
  final int initialIndex;
  final List<dynamic> ads;

  const ArticlesFeedScreen({
    super.key,
    required this.articles,
    required this.initialIndex,
    this.ads = const [],
  });

  @override
  State<ArticlesFeedScreen> createState() => _ArticlesFeedScreenState();
}

class _ArticlesFeedScreenState extends State<ArticlesFeedScreen> {
  late PageController _pageController;
  double _currentPage = 0;
  final Map<int, VideoPlayerController> _videoControllers = {};

  List<dynamic> get _feedItems {
    if (widget.ads.isEmpty) return widget.articles;
    final List<dynamic> items = [];
    int adIndex = 0;
    for (int i = 0; i < widget.articles.length; i++) {
      items.add(widget.articles[i]);
      if ((i + 1) % 5 == 0 && adIndex < widget.ads.length) {
        items.add({'_isAd': true, ...(widget.ads[adIndex] as Map<String, dynamic>)});
        adIndex = (adIndex + 1) % widget.ads.length;
      }
    }
    return items;
  }

  int get _initialFeedIndex {
    if (widget.ads.isEmpty) return widget.initialIndex;
    return widget.initialIndex + (widget.initialIndex ~/ 5);
  }

  @override
  void initState() {
    super.initState();
    final startPage = _initialFeedIndex;
    _currentPage = startPage.toDouble();
    _pageController = PageController(initialPage: startPage);
    _pageController.addListener(_onScroll);
    _initVideo(startPage);
    _initVideo(startPage + 1);
  }

  void _onScroll() {
    final page = _pageController.page;
    if (page != null && mounted) setState(() => _currentPage = page);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    for (final c in _videoControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _initVideo(int index) async {
    final items = _feedItems;
    if (index < 0 || index >= items.length) return;
    final item = items[index];
    if (item is Map && (item as Map)['_isAd'] == true) return;
    if (_videoControllers.containsKey(index)) return;
    final rawUrl = (item as Map<String, dynamic>)['videoUrl']?.toString() ?? '';
    if (rawUrl.isEmpty) return;
    String url = rawUrl.trim();
    if (url.startsWith('/')) {
      url = 'https://visoniq.info$url';
    } else if (!url.startsWith('http')) {
      url = 'https://visoniq.info/$url';
    }
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoControllers[index] = c;
      await c.initialize();
      if (!mounted) return;
      setState(() {});
      if (_currentPage.round() == index) {
        c.play();
        c.setLooping(true);
      }
    } catch (_) {
      _videoControllers.remove(index);
    }
  }

  void _onPageChanged(int index) {
    for (final e in _videoControllers.entries) {
      if (e.key != index) e.value.pause();
    }
    _videoControllers[index]?.play();
    _initVideo(index + 1);
    _initVideo(index - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _feedItems.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final double value = index.toDouble() - _currentPage;
          final item = _feedItems[index];
          final isAd = item is Map && (item as Map)['_isAd'] == true;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(value * (pi / 2)),
            alignment: value > 0 ? Alignment.topCenter : Alignment.bottomCenter,
            child: isAd
                ? _ArticleAdPage(ad: item, onBack: () => Navigator.pop(context))
                : _ArticleFeedPage(
                    article: item,
                    videoController: _videoControllers[index],
                    onBack: () => Navigator.pop(context),
                  ),
          );
        },
      ),
    );
  }
}

class _ArticleFeedPage extends StatelessWidget {
  final dynamic article;
  final VideoPlayerController? videoController;
  final VoidCallback onBack;

  const _ArticleFeedPage({
    required this.article,
    this.videoController,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final a = article as Map<String, dynamic>;
    final title = lang.getNewsContent(a, 'title');
    final summary = lang.getNewsContent(a, 'summary');
    final content = lang.getNewsContent(a, 'content');
    final explanation = lang.getNewsContent(a, 'explanation');
    final body = summary.isNotEmpty ? summary : (content.isNotEmpty ? content : explanation);
    final rawImage = a['image']?.toString() ?? '';
    final imageUrl = rawImage.isNotEmpty ? rawImage : 'asset:refranceimages/Group (16).png';
    final categoryName = a['category']?['name']?.toString() ?? '';
    final publishedAt = a['publishedAt'];
    final screenHeight = MediaQuery.of(context).size.height;
    final topPad = MediaQuery.of(context).padding.top;
    final isVideoReady = videoController != null && videoController!.value.isInitialized;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: screenHeight * 0.52,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isVideoReady)
                  GestureDetector(
                    onTap: () {
                      if (videoController!.value.isPlaying) {
                        videoController!.pause();
                      } else {
                        videoController!.play();
                      }
                    },
                    child: FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: videoController!.value.size.width,
                        height: videoController!.value.size.height,
                        child: VideoPlayer(videoController!),
                      ),
                    ),
                  )
                else
                  _MediaImage(imageUrl: imageUrl),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.25, 0.7, 1.0],
                        colors: [
                          Colors.black54,
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black54,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: topPad + 8,
                  left: 14,
                  child: GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    ),
                  ),
                ),
                if (categoryName.isNotEmpty)
                  Positioned(
                    top: topPad + 8,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AsiazeApp.primaryRed,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        categoryName,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                if (isVideoReady && !videoController!.value.isPlaying)
                  const Center(
                    child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 72),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ASIAZE  •  ${formatPublishedDate(publishedAt)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title.isNotEmpty ? title : 'No Title',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.black, height: 1.2),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      body,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.55),
                      overflow: TextOverflow.fade,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Save button
                      ValueListenableBuilder<List<SavedArticle>>(
                        valueListenable: SavedArticlesStore.saved,
                        builder: (context, saved, _) {
                          final isSaved = saved.any((e) => e.title == title);
                          return GestureDetector(
                            onTap: () {
                              SavedArticlesStore.toggle(SavedArticle(
                                image: imageUrl,
                                title: title,
                                subtitle: body,
                                meta: 'ASIAZE  •  ${formatPublishedDate(publishedAt)}',
                              ));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSaved ? AsiazeApp.primaryRed.withOpacity(0.1) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isSaved ? Icons.bookmark : Icons.bookmark_border,
                                color: isSaved ? AsiazeApp.primaryRed : Colors.black87,
                                size: 22,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      // Read More button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => ExplainSheet(
                                title: title,
                                summary: body,
                                explanation: explanation.isNotEmpty ? explanation : body,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Read More',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Share button
                      GestureDetector(
                        onTap: () async {
                          await Share.share(
                            '$title\n\n$body\n\nRead more on asiaze',
                            subject: title,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.share, color: Colors.black87, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaImage extends StatelessWidget {
  final String imageUrl;
  const _MediaImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('asset:')) {
      return Image.asset(imageUrl.replaceFirst('asset:', ''), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Image.asset('refranceimages/Group (16).png', fit: BoxFit.cover),
    );
  }
}
// ---------------- Article Ad Page ----------------
class _ArticleAdPage extends StatelessWidget {
  final dynamic ad;
  final VoidCallback onBack;

  const _ArticleAdPage({required this.ad, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final a = ad as Map<String, dynamic>;
    String imageUrl = a['imageUrl']?.toString() ?? '';
    if (imageUrl.startsWith('/uploads/')) imageUrl = '${ApiService.baseServerUrl}$imageUrl';
    final title = a['title']?.toString() ?? 'Advertisement';
    final clickUrl = a['clickUrl']?.toString() ?? '';
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(imageUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1a1a2e)))
          else
            Container(color: const Color(0xFF1a1a2e)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.35, 0.65, 1.0],
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: topPad + 8,
            left: 14,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              ),
            ),
          ),
          // Sponsored badge
          Positioned(
            top: topPad + 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign, color: Colors.black, size: 13),
                  SizedBox(width: 4),
                  Text('Sponsored', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          // Bottom ad content
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  if (clickUrl.isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.tryParse(clickUrl);
                        if (uri != null && await canLaunchUrl(uri)) {
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Learn More',
                          style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Explain Sheet ----------------
class ExplainSheet extends StatelessWidget {
  final String title;
  final String summary;
  final String explanation;

  const ExplainSheet({
    super.key,
    required this.title,
    required this.summary,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: red, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Detailed Explanation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () async {
                        final shareText = '$title\n\n$summary\n\n$explanation\n\nRead more on asiaze';
                        await Share.share(
                          shareText,
                          subject: title,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: red, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      summary,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.article_outlined, color: red, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Detailed Explanation',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------- Reward Screen ----------------
class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  int _points = 0;
  List<dynamic> _rewards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      print('🔍 Fetching wallet for userId: $userId');
      
      if (userId != null && userId.isNotEmpty) {
        final response = await ApiService.getUserProfile(userId);
        final rewards = await ApiService.getRewards();
        
        print('📦 User data: $response');
        
        // Extract user from response
        final user = response['user'] ?? response;
        final walletBalance = user['walletBalance'] ?? 0;
        
        print('💰 Wallet balance: $walletBalance');
        
        setState(() {
          _points = walletBalance is int ? walletBalance : int.tryParse(walletBalance.toString()) ?? 0;
          _rewards = rewards.where((r) => r['available'] == true).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('❌ Error fetching wallet: $e');
      setState(() => _loading = false);
    }
  }

  void _showRewardDialog(Map<String, dynamic> reward) {
    final requiredPoints = reward['points'] ?? 0;
    final canRedeem = _points >= requiredPoints;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reward['name'] ?? 'Reward'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reward['imageUrl'] != null && reward['imageUrl'].toString().isNotEmpty)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    reward['imageUrl'].toString().startsWith('http') 
                        ? reward['imageUrl'].toString()
                        : '${ApiService.baseServerUrl}${reward['imageUrl']}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.card_giftcard, size: 40),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(reward['description'] ?? 'Redeem this reward'),
            const SizedBox(height: 16),
            Text('Required: ${reward['points']} points'),
            Text('Your points: $_points'),
            if (!canRedeem)
              Text(
                'Insufficient points',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (canRedeem)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _redeemReward(reward);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AsiazeApp.primaryRed),
              child: const Text('Redeem', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId != null && userId.isNotEmpty) {
        // Deduct points and generate code
        final requiredPoints = reward['points'] ?? 0;
        final newBalance = _points - requiredPoints;
        
        // Update local balance
        setState(() {
          _points = newBalance.toInt();
        });
        
        // Show success with code
        final code = 'ASZ${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        _showRedemptionSuccess(reward, code);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Redemption failed: $e')),
      );
    }
  }

  void _showRedemptionSuccess(Map<String, dynamic> reward, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Reward Redeemed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${reward['name']} redeemed successfully!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Code: $code',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Save this code! It can only be copied once.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(Provider.of<LanguageProvider>(context).translate('reward_points')),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.card_giftcard, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '$_points Points',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Provider.of<LanguageProvider>(context).translate('share_earn'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black87, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invite feature coming soon!')),
                          );
                        },
                        child: Text(Provider.of<LanguageProvider>(context).translate('invite_friends'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      Provider.of<LanguageProvider>(context).translate('available_rewards'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._rewards.map((r) {
                    final imageUrl = r['imageUrl'] ?? '';
                    final fullImageUrl = imageUrl.startsWith('http') 
                        ? imageUrl 
                        : '${ApiService.baseServerUrl}$imageUrl';
                    return _RewardCard(
                      imageUrl: fullImageUrl,
                      title: r['name'] ?? '',
                      points: 'Required ${r['points']} pts',
                      red: red,
                      onTap: () => _showRewardDialog(r),
                    );
                  }),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Points are verified through your share/referral activity.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String points;
  final Color red;
  final VoidCallback? onTap;

  const _RewardCard({
    required this.imageUrl,
    required this.title,
    required this.points,
    required this.red,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) {
                          return const Center(
                            child: Icon(Icons.card_giftcard, size: 24, color: Colors.grey),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.card_giftcard, size: 24, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    points,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ---------------- Preferences (Language & Interests) ----------------
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});
  static const String routeName = '/preferences';

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String _lang = 'EN';
  final List<String> _languages = const ['EN', 'HIN', 'BEN'];
  List<Map<String, dynamic>> _categories = [];
  final Set<String> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await ApiService.getCategories();
      setState(() {
        _categories = List<Map<String, dynamic>>.from(categories);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Welcome! Let\'s personalize your news experience',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Text(
                lang.translate('choose_language'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _languages.map((l) => _langChip(l, red)).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                lang.translate('select_interests'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _categories.isEmpty
                      ? const Center(child: Text('No categories available'))
                      : GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.9,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: _categories.map((c) => _interestTile(lang.getCategoryLabel(c), red)).toList(),
                        ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 240,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: () async {
                      if (_selected.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select at least one interest')),
                        );
                        return;
                      }
                      
                      final prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getString('userId');
                      
                      // Save category IDs for filtering
                      final selectedIds = _categories
                          .where((c) => _selected.contains(c['name'].toString()))
                          .map((c) => c['_id'].toString())
                          .toList();
                      
                      // Save to local storage
                      await prefs.setString('language', _lang);
                      await prefs.setStringList('interests', _selected.toList());
                      await prefs.setStringList('categoryIds', selectedIds);
                      await prefs.remove('isNewUser'); // Clear new user flag
                      
                      print('Saved preferences - Language: $_lang, Interests: ${_selected.toList()}, IDs: $selectedIds');
                      
                      // Save to backend if userId exists
                      if (userId != null && userId.isNotEmpty) {
                        try {
                          print('Updating backend with userId: $userId, language: $_lang, categoryIds: $selectedIds');
                          final result = await ApiService.updateUserPreferences(userId, _lang, selectedIds);
                          print('Backend preferences updated successfully: $result');
                          
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Preferences saved successfully!')),
                          );
                        } catch (e) {
                          print('Failed to update backend preferences: $e');
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Warning: Could not sync to server: $e')),
                          );
                        }
                      } else {
                        print('No userId found, skipping backend update');
                      }
                      
                      if (!mounted) return;
                      Navigator.of(context).pushReplacementNamed(MainNav.routeName);
                    },
                    child: Text(lang.translate('continue')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langChip(String value, Color red) {
    final selected = _lang == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: GestureDetector(
        onTap: () => setState(() => _lang = value),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? red : Colors.white,
            border: Border.all(color: Colors.black87, width: selected ? 0 : 1.5),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _interestTile(String label, Color red) {
    final selected = _selected.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _selected.remove(label);
          } else {
            _selected.add(label);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: selected ? red : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 12,
              child: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? Colors.white : Colors.black54,
                size: 20,
              ),
            ),
            Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Notifications Screen ----------------
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('language') ?? 'EN';
      final notifications = await ApiService.getNotifications(langCode);
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _formatTime(dynamic sentAt) {
    if (sentAt == null) return 'Recently';
    try {
      final dt = DateTime.parse(sentAt.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return 'Recently';
    }
  }

  Future<void> _handleNotificationTap(dynamic notif) async {
    final contentType = notif['contentType'];
    final contentId = notif['contentId'];

    if (contentId == null || contentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content not available')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('language') ?? 'EN';
      final language = langCode == 'HIN' ? 'hindi' : (langCode == 'BEN' ? 'bengali' : 'english');

      if (contentType == 'News') {
        final news = await ApiService.getNews(language: language);
        final article = news.firstWhere(
          (n) => n['_id'].toString() == contentId.toString(),
          orElse: () => null,
        );

        if (article != null && mounted) {
          final articleIndex = news.indexOf(article);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ArticlesFeedScreen(
                articles: news,
                initialIndex: articleIndex < 0 ? 0 : articleIndex,
              ),
            ),
          );
        }
      } else if (contentType == 'Reel') {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VideosScreen()),
          );
        }
      } else if (contentType == 'Story') {
        final stories = await ApiService.getStories();
        final storyIndex = stories.indexWhere(
          (s) => s['_id'].toString() == contentId.toString(),
        );

        if (storyIndex != -1 && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StoryViewerScreen(
                stories: stories,
                initialIndex: storyIndex,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load content: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No notifications yet', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final notif = _notifications[i];
                    final highlight = i == 0;
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0.5,
                      child: ListTile(
                        leading: Icon(
                          Icons.notifications,
                          color: highlight ? AsiazeApp.primaryRed : Colors.black87,
                        ),
                        title: Text(
                          notif['title'] ?? 'Notification',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(notif['message'] ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(notif['sentAt']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      onTap: () => _handleNotificationTap(notif),
                      ),
                    );
                  },
                ),
    );
  }
}

