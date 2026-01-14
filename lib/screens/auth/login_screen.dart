import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/animations/fade_in_slide.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = authProvider.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load user data. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? route;
    switch (user.role) {
      case UserRole.admin:
        if (!user.verified || user.status != VerificationStatus.verified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your admin account is not verified yet.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        route = '/admin/dashboard';
        break;
      case UserRole.agency:
        if (!user.verified ||
            user.status == VerificationStatus.pending ||
            user.status == VerificationStatus.rejected) {
          route = '/agency/verification';
        } else {
          route = '/agency/dashboard';
        }
        break;
      case UserRole.traveler:
        route = '/traveler/home';
        break;
    }

    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background with Image and Blur
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?q=80&w=2070&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // TOP LOGO SECTION
                    FadeInSlide(
                      index: 0,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'TourEase',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 24, left: 4),
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00BFA5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'SMART TRAVEL MARKETPLACE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),

                    // LOGIN CARD
                    FadeInSlide(
                      index: 1,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 450),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Welcome back',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 32),

                                    // Email Field
                                    _buildRoundedField(
                                      controller: _emailController,
                                      label: 'Email',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Password Field
                                    _buildRoundedField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      icon: Icons.lock_outlined,
                                      isPassword: true,
                                      obscureText: _obscurePassword,
                                      onTogglePassword: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Remember me & Recovery
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: true,
                                              onChanged: (_) {},
                                              activeColor:
                                                  theme.colorScheme.primary,
                                              side: const BorderSide(
                                                color: Colors.white54,
                                              ),
                                            ),
                                            const Text(
                                              'Remember me',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        TextButton(
                                          onPressed: () {},
                                          child: const Text(
                                            'Recovery password',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),

                                    // Sign In Button
                                    _buildSignInButton(),

                                    const SizedBox(height: 32),

                                    // OR DIVIDER
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Text(
                                            'OR',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),

                                    // Admin Portal Link
                                    Center(
                                      child: TextButton(
                                        onPressed: () =>
                                            context.push('/admin/login'),
                                        child: const Text(
                                          'Admin Portal',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Footer
                                    Center(
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          const Text(
                                            "Don't have an account?",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                context.push('/signup'),
                                            child: Text(
                                              'Create an account',
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundedField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black, fontSize: 15),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
        prefixIcon: Icon(icon, color: Colors.grey.shade700, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey.shade700,
                  size: 22,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
      validator: validator,
    );
  }

  Widget _buildSignInButton() {
    final authProvider = context.watch<AuthProvider>();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: authProvider.isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00FFC2), // Bright Cyan/Teal
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: authProvider.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign In',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
      ),
    );
  }
}
