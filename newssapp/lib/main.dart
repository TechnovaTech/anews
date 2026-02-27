import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
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
                              final result = await ApiService.googleSignIn(
                                account.email,
                                account.displayName ?? '',
                                account.id,
                                '', // State will be updated in profile
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
                              Navigator.of(context).pushReplacementNamed(MainNav.routeName);
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
                            setState(() {
                              _isGoogleSignUp = true;
                              _nameCtrl.text = account.displayName ?? '';
                              _emailCtrl.text = account.email;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Google account connected! Please select your state.')),
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

  final _pages = const [
    HomeScreen(),
    VideosScreen(),
    StoryGridScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
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
                                explanation: explanation,
                                categoryId: p['category']?['_id']?.toString(),
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
  const VideosScreen({super.key});

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
  final int views;
  const _VideoModel({required this.id, required this.url, required this.image, required this.title, this.description = '', this.category = 'News', required this.source, required this.timeAgo, this.likes = 0, this.views = 0});
}

class _VideosScreenState extends State<VideosScreen> {
  bool _muted = true;
  final PageController _pageController = PageController();
  List<_VideoModel> _items = [];
  final List<VideoPlayerController> _controllers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchReels();
  }

  Future<void> _fetchReels() async {
    try {
      print('🎬 Fetching reels from API...');
      final prefs = await SharedPreferences.getInstance();
      final categoryIds = prefs.getStringList('categoryIds') ?? [];
      final langCode = prefs.getString('language') ?? 'EN';
      print('Language code: $langCode, Categories: $categoryIds');
      
      List<dynamic> reels;
      if (categoryIds.isEmpty) {
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
                views: r['views'] ?? 0,
              );
            }).toList();
            _loading = false;
          });
        }
      }

      for (final v in _items) {
        VideoPlayerController c;
        if (v.url.startsWith('http://') || v.url.startsWith('https://')) {
          c = VideoPlayerController.networkUrl(Uri.parse(v.url));
        } else {
          c = VideoPlayerController.asset(v.url);
        }
        c.setLooping(true);
        c.setVolume(_muted ? 0 : 1);
        _controllers.add(c);
      }
      
      for (var i = 0; i < _controllers.length; i++) {
        _controllers[i].initialize().then((_) {
          if (mounted) setState(() {});
          if (i == 0) {
            _controllers[0].setVolume(_muted ? 0 : 1);
            _controllers[0].play();
          }
        }).catchError((error) {
          print('Error initializing video $i: $error');
        });
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
    for (final c in _controllers) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    for (int i = 0; i < _controllers.length; i++) {
      final c = _controllers[i];
      if (i == index) {
        c.setVolume(_muted ? 0 : 1);
        c.play();
      } else {
        c.pause();
      }
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
                  itemCount: _items.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final controller = _controllers[index];
                    return _VideoPage(
                      controller: controller,
                      item: item,
                      red: red,
                      muted: _muted,
                      onToggleMute: () {
                        setState(() {
                          _muted = !_muted;
                          controller.setVolume(_muted ? 0 : 1);
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
  bool _showDetails = false;
  String? _reelId;

  @override
  void initState() {
    super.initState();
    _reelId = widget.item.id;
    _likeCount = widget.item.likes;
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
                        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
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
          top: MediaQuery.of(context).size.height * 0.45,
          child: Column(
            children: [
              _CircleAction(
                icon: _liked ? Icons.favorite : Icons.favorite_border,
                label: _likeCount >= 1000 ? '${(_likeCount / 1000).toStringAsFixed(1)}k' : '$_likeCount',
                selected: _liked,
                labelBelow: true,
                onTap: () async {
                  setState(() {
                    _liked = !_liked;
                    _likeCount += _liked ? 1 : -1;
                  });
                  // Note: Add API call here when reelId is available
                  // await ApiService.likeReel(reelId, _liked);
                },
              ),
              const SizedBox(height: 16),
              _CircleAction(
                icon: _saved ? Icons.bookmark : Icons.bookmark_border,
                selected: _saved,
                onTap: () {
                  setState(() {
                    _saved = !_saved;
                    SavedReelsStore.toggle(SavedReel(
                      url: item.url,
                      title: item.title,
                      thumbnail: item.image,
                    ));
                  });
                },
              ),
              const SizedBox(height: 16),
              _CircleAction(
                icon: Icons.send,
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
                              child: const Icon(Icons.close, color: Colors.white, size: 24),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'By ${item.source} • ${item.timeAgo}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (item.description.isNotEmpty)
                          Text(
                            item.description,
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: selected ? AsiazeApp.primaryRed.withOpacity(0.85) : Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(icon, color: Colors.white),
    );

    if (labelBelow && label != null) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 48, height: 48, child: Center(child: circle)),
            const SizedBox(height: 6),
            Text(label!, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            circle,
            if (label != null)
              Positioned(
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(label!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
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
          onPressed: () => Navigator.of(context).pop(),
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
                                if (mediaItems.isNotEmpty) {
                                  imageUrl = mediaItems[0]['url']?.toString() ?? '';
                                } else {
                                  imageUrl = story['image']?.toString() ?? '';
                                }
                                
                                if (imageUrl.startsWith('/uploads/')) {
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
      duration: const Duration(seconds: 5),
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
                    if (mediaItems.length > 1)
                      Positioned(
                        top: 60,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            mediaItems.length,
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == _currentMediaIndex ? Colors.white : Colors.white.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
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
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _liked = !_liked),
                              child: Icon(
                                _liked ? Icons.favorite : Icons.favorite_border,
                                color: _liked ? Colors.red : Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Icon(Icons.send, color: Colors.white, size: 28),
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
                          builder: (context) => ArticleDetailScreen(
                            imageUrl: imageUrl,
                            title: title.isNotEmpty ? title : 'No Title',
                            subtitle: summary.isNotEmpty ? summary : content,
                            meta: 'ASIAZE • ${formatPublishedDate(article['publishedAt'])}',
                            explanation: explanation,
                            categoryId: article['category']?['_id']?.toString(),
                            videoUrl: article['videoUrl'],
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
                      builder: (context) => ArticleDetailScreen(
                        imageUrl: imageUrl,
                        title: title.isNotEmpty ? title : 'No Title',
                        subtitle: summary.isNotEmpty ? summary : content,
                        meta: 'ASIAZE • ${formatPublishedDate(article['publishedAt'])}',
                        explanation: explanation,
                        categoryId: article['category']?['_id']?.toString(),
                        videoUrl: article['videoUrl'],
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
                  final thumbnail = reel['thumbnail'] ?? 'asset:refranceimages/Group (16).png';
                  
                  return InkWell(
                    onTap: () {
                      // Navigate to reel player
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12, bottom: 16),
                      decoration: BoxDecoration(
                        color: red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            thumbnail.startsWith('asset:')
                                ? Image.asset(
                                    thumbnail.replaceFirst('asset:', ''),
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    thumbnail,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: red,
                                        child: const Center(
                                          child: Icon(Icons.play_circle_outline, color: Colors.white, size: 40),
                                        ),
                                      );
                                    },
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

class FeedList extends StatefulWidget {
  final String categoryName;
  final String? categoryId;
  const FeedList({super.key, required this.categoryName, this.categoryId});

  @override
  State<FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<FeedList> with SingleTickerProviderStateMixin {
  List<dynamic> _news = [];
  bool _loading = true;
  int _currentIndex = 0;
  double _dragOffset = 0.0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() {
          _dragOffset = _animation.value;
        });
      });
    _fetchNews();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      if (mounted) {
        setState(() {
          _news = news;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset -= details.primaryDelta!;
      final screenHeight = MediaQuery.of(context).size.height;
      _dragOffset = _dragOffset.clamp(-screenHeight, screenHeight);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    final velocity = details.primaryVelocity ?? 0;
    
    if (velocity < -500 || _dragOffset > screenHeight * 0.25) {
      // Swipe up - go to next card
      if (_currentIndex < _news.length - 1) {
        _animation = Tween<double>(
          begin: _dragOffset,
          end: screenHeight,
        ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
        _animationController.forward(from: 0).then((_) {
          setState(() {
            _currentIndex++;
            _dragOffset = 0.0;
          });
        });
      } else {
        _animateSnapBack();
      }
    } else if (velocity > 500 || _dragOffset < -screenHeight * 0.25) {
      // Swipe down - go to previous card
      if (_currentIndex > 0) {
        _animation = Tween<double>(
          begin: _dragOffset,
          end: -screenHeight,
        ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
        _animationController.forward(from: 0).then((_) {
          setState(() {
            _currentIndex--;
            _dragOffset = 0.0;
          });
        });
      } else {
        _animateSnapBack();
      }
    } else {
      // Snap back
      _animateSnapBack();
    }
  }

  void _animateSnapBack() {
    _animation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    
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

    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: Stack(
        children: [
          // Current card - stays in place
          if (_currentIndex < _news.length)
            Positioned.fill(
              child: _buildNewsCard(_currentIndex, lang),
            ),
          // Next card - slides up from bottom when swiping up
          if (_currentIndex + 1 < _news.length && _dragOffset > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: screenHeight - _dragOffset,
              child: _buildNewsCard(_currentIndex + 1, lang),
            ),
          // Previous card - slides down from top when swiping down
          if (_currentIndex > 0 && _dragOffset < 0)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: screenHeight + _dragOffset,
              child: _buildNewsCard(_currentIndex - 1, lang),
            ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(int index, LanguageProvider lang) {
    final article = _news[index];
    final title = lang.getNewsContent(article, 'title');
    final summary = lang.getNewsContent(article, 'summary');
    final content = lang.getNewsContent(article, 'content');
    final explanation = lang.getNewsContent(article, 'explanation');
    final videoUrl = article['videoUrl'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: NewsCard(
        imageUrl: article['image'] ?? 'asset:refranceimages/Group (16).png',
        title: title.isNotEmpty ? title : 'No Title',
        subtitle: summary.isNotEmpty ? summary : content,
        meta: 'ASIAZE • ${formatPublishedDate(article['publishedAt'])}',
        explanation: explanation,
        categoryId: article['category']?['_id']?.toString(),
        videoUrl: videoUrl,
      ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy - Coming Soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(lang.translate('terms_conditions')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms & Conditions - Coming Soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(lang.translate('about_us')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('About Us - Coming Soon')),
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

class SavedReelsTab extends StatelessWidget {
  const SavedReelsTab({super.key});

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
              onTap: () {},
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: Icon(Icons.play_circle_outline, size: 48, color: Colors.white),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            r.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => SavedReelsStore.toggle(r),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: red,
                          shape: BoxShape.circle,
                        ),
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
  final String? explanation;
  final String? categoryId;
  final String? videoUrl;
  const NewsCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.meta,
    this.explanation,
    this.categoryId,
    this.videoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(
              imageUrl: imageUrl,
              title: title,
              subtitle: subtitle,
              meta: meta,
              explanation: explanation ?? '',
              categoryId: categoryId,
              videoUrl: videoUrl,
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
              // Image section - 60% of card
              Expanded(
                flex: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    (imageUrl.startsWith('asset:')
                        ? Image.asset(
                            imageUrl.replaceFirst('asset:', ''),
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                          )),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ValueListenableBuilder<List<SavedArticle>>(
                          valueListenable: SavedArticlesStore.saved,
                          builder: (context, saved, _) {
                            final isSaved = saved.any((e) => e.title == title);
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    SavedArticlesStore.toggle(SavedArticle(
                                      image: imageUrl,
                                      title: title,
                                      subtitle: subtitle,
                                      meta: meta,
                                    ));
                                  },
                                  child: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final shareText = '$title\n\nRead more on asiaze';
                                    await Share.share(
                                      shareText,
                                      subject: title,
                                    );
                                  },
                                  child: const Icon(Icons.share, color: Colors.white, size: 18),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content section - 40% of card
              Expanded(
                flex: 40,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              meta,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (explanation != null && explanation!.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => ExplainSheet(
                                    title: title,
                                    summary: subtitle,
                                    explanation: explanation!,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.article_outlined, size: 14),
                              label: const Text('Read More', style: TextStyle(fontSize: 11)),
                              style: TextButton.styleFrom(
                                foregroundColor: red,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        ),
      ),
    );
  }
}

// ---------------- Article Detail Screen ----------------
class ArticleDetailScreen extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String meta;
  final String explanation;
  final String? categoryId;
  final String? videoUrl;

  const ArticleDetailScreen({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.explanation,
    this.categoryId,
    this.videoUrl,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _otherNews = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loadingOtherNews = false;
  bool _hasLoadedOtherNews = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load content immediately when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOtherNews();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Content is already loaded on init, this is just a backup
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.3 && 
        !_loadingOtherNews && !_hasLoadedOtherNews) {
      _loadOtherNews();
    }
  }

  Future<void> _loadOtherNews() async {
    if (_loadingOtherNews || _hasLoadedOtherNews) return;
    
    setState(() => _loadingOtherNews = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('language') ?? 'EN';
      final language = langCode == 'HIN' ? 'hindi' : (langCode == 'BEN' ? 'bengali' : 'english');
      
      // Get categories and news
      final categories = await ApiService.getCategories();
      final allNews = await ApiService.getNews(language: language);
      
      // Filter out current article and get diverse news from different categories
      final otherNews = allNews.where((news) => news['title'] != widget.title).toList();
      
      setState(() {
        _categories = List<Map<String, dynamic>>.from(categories);
        _otherNews = otherNews.take(10).toList(); // Limit to 10 articles
        _loadingOtherNews = false;
        _hasLoadedOtherNews = true;
      });
    } catch (e) {
      setState(() => _loadingOtherNews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final red = AsiazeApp.primaryRed;
    final lang = Provider.of<LanguageProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.7;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Article Card (70% of screen)
              Container(
                height: cardHeight,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Video/Image Section (60% of card)
                    Expanded(
                      flex: 60,
                      child: Stack(
                        children: [
                          // Video player if video exists, otherwise show image
                          if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Container(
                                width: double.infinity,
                                color: Colors.black,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Video thumbnail (image)
                                    if (widget.imageUrl.isNotEmpty)
                                      widget.imageUrl.startsWith('asset:')
                                          ? Image.asset(
                                              widget.imageUrl.replaceFirst('asset:', ''),
                                              fit: BoxFit.cover,
                                            )
                                          : Image.network(
                                              widget.imageUrl,
                                              fit: BoxFit.cover,
                                            ),
                                    // Play button overlay
                                    Center(
                                      child: Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 45),
                                      ),
                                    ),
                                    // Tap to play
                                    Positioned.fill(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            // TODO: Implement video player
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Video player coming soon')),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: widget.imageUrl.startsWith('asset:')
                                  ? Image.asset(
                                      widget.imageUrl.replaceFirst('asset:', ''),
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      widget.imageUrl,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          // Back button overlay
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content Section (40% of card)
                    Expanded(
                      flex: 40,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3,
                                        color: Colors.black,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.subtitle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.meta,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom Actions Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bookmark Icon
                    ValueListenableBuilder<List<SavedArticle>>(
                      valueListenable: SavedArticlesStore.saved,
                      builder: (context, saved, _) {
                        final isSaved = saved.any((e) => e.title == widget.title);
                        return IconButton(
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            size: 28,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            SavedArticlesStore.toggle(SavedArticle(
                              image: widget.imageUrl,
                              title: widget.title,
                              subtitle: widget.subtitle,
                              meta: widget.meta,
                            ));
                          },
                        );
                      },
                    ),
                    
                    // Read More Button
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => ExplainSheet(
                                title: widget.title,
                                summary: widget.subtitle,
                                explanation: widget.explanation,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Read More',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Share Icon
                    IconButton(
                      icon: const Icon(Icons.share, size: 28, color: Colors.black),
                      onPressed: () async {
                        final shareText = '${widget.title}\n\n${widget.subtitle}\n\nRead more on asiaze';
                        await Share.share(
                          shareText,
                          subject: widget.title,
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Scroll Indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 20),
                      Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        'next',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Loading indicator
              if (_loadingOtherNews)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              
              // Recommendation Section (only section on scroll)
              if (_hasLoadedOtherNews && _otherNews.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Recommendation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: red,
                    ),
                  ),
                ),
                
                // Recommendation List (small thumbnails)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _otherNews.length,
                  itemBuilder: (context, index) {
                    final article = _otherNews[index];
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
                            builder: (context) => ArticleDetailScreen(
                              imageUrl: imageUrl,
                              title: title.isNotEmpty ? title : 'No Title',
                              subtitle: summary.isNotEmpty ? summary : content,
                              meta: 'ASIAZE • ${formatPublishedDate(article['publishedAt'])}',
                              explanation: explanation,
                              categoryId: article['category']?['_id']?.toString(),
                              videoUrl: article['videoUrl'],
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
              ]
            ],
          ),
        ),
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
          final lang = Provider.of<LanguageProvider>(context, listen: false);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(
                imageUrl: article['image'] ?? 'asset:refranceimages/Group (16).png',
                title: lang.getNewsContent(article, 'title'),
                subtitle: lang.getNewsContent(article, 'summary'),
                meta: 'ASIAZE • ${formatPublishedDate(article['publishedAt'])}',
                explanation: lang.getNewsContent(article, 'explanation'),
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

