// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../design_system/widgets/modern_button.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  final VoidCallback onSkip;
  final bool initialIsSignUp;
  
  const AuthScreen({
    super.key,
    required this.onAuthSuccess,
    required this.onSkip,
    this.initialIsSignUp = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // AuthService static sınıf olduğu için instance oluşturmaya gerek yok
  final UserProfileService _userProfileService = UserProfileService();
  
  late bool _isSignUp;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await AuthService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
        
        // Create user profile after successful signup
        await _userProfileService.createProfileFromCurrentUser();
        
        if (mounted) {
          // For new users, show profile completion
          widget.onAuthSuccess();
        }
      } else {
        await AuthService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        // Check if user profile exists, create if not
        final hasProfile = await _userProfileService.hasUserProfile();
        if (!hasProfile) {
          await _userProfileService.createProfileFromCurrentUser();
        }
        
        // Firebase'den kullanıcı verilerini yükle (geçici olarak devre dışı)
        // await FirebaseSyncService.onUserSignIn();
        
        if (mounted) {
          widget.onAuthSuccess();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen e-posta adresinizi girin';
      });
      return;
    }

    try {
      await AuthService.resetPassword(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre sıfırlama e-postası gönderildi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.signInWithGoogle();
      if (result != null && mounted) {
        // Check if user profile exists, create if not
        final hasProfile = await _userProfileService.hasUserProfile();
        if (!hasProfile) {
          await _userProfileService.createProfileFromCurrentUser();
        }
        
        // Firebase'den kullanıcı verilerini yükle (geçici olarak devre dışı)
        // await FirebaseSyncService.onUserSignIn();
        
        widget.onAuthSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Header
              _buildHeader()
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 600))
                .slideY(begin: -0.3, duration: const Duration(milliseconds: 600)),
              
              const SizedBox(height: 40),
              
              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name field (only for sign up)
                    if (_isSignUp) ...[
                      _buildNameField()
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 400))
                        .slideX(begin: -0.3, duration: const Duration(milliseconds: 400)),
                      const SizedBox(height: 16),
                    ],
                    
                    // Email field
                    _buildEmailField()
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 500))
                      .slideX(begin: 0.3, duration: const Duration(milliseconds: 500)),
                    
                    const SizedBox(height: 16),
                    
                    // Password field
                    _buildPasswordField()
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 600))
                      .slideX(begin: -0.3, duration: const Duration(milliseconds: 600)),
                    
                    if (!_isSignUp) ...[
                      const SizedBox(height: 8),
                      _buildForgotPassword(),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Error message
                    if (_errorMessage != null) ...[
                      _buildErrorMessage(),
                      const SizedBox(height: 16),
                    ],
                    
                    // Auth button
                    _buildAuthButton()
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 700))
                      .scale(duration: const Duration(milliseconds: 700)),
                    
                    const SizedBox(height: 24),
                    
                    // Divider
                    _buildDivider(),
                    
                    const SizedBox(height: 24),
                    
                    // Social login buttons
                    _buildSocialButtons()
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 800))
                      .slideY(begin: 0.3, duration: const Duration(milliseconds: 800)),
                    
                    const SizedBox(height: 32),
                    
                    // Toggle sign up/sign in
                    _buildToggleAuth()
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 900)),
                    
                    const SizedBox(height: 16),
                    
                    // Skip button
                    _buildSkipButton()
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 1000)),
                    
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App logo/icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(77),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.sports_soccer,
            size: 40,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'GOALITYCS',
          style: AppTypography.headlineLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          _isSignUp ? 'Hesap Oluşturun!' : 'Tekrar Hoş Geldiniz!',
          style: AppTypography.headlineSmall.copyWith(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Ad Soyad',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Lütfen adınızı girin';
        }
        if (value.trim().length < 2) {
          return 'Ad en az 2 karakter olmalıdır';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'E-posta',
        prefixIcon: const Icon(Icons.email_outlined),
        suffixIcon: _emailController.text.isNotEmpty && 
                   _emailController.text.contains('@') &&
                   _emailController.text.contains('.')
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Lütfen e-posta adresinizi girin';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Geçerli bir e-posta adresi girin';
        }
        return null;
      },
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Şifre',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen şifrenizi girin';
        }
        if (_isSignUp && value.length < 6) {
          return 'Şifre en az 6 karakter olmalıdır';
        }
        return null;
      },
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _handleForgotPassword,
        child: Text(
          'Şifremi Unuttum?',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton() {
    return ModernButton(
      text: _isSignUp ? 'Hesap Oluştur' : 'Giriş Yap',
      onPressed: _isLoading ? null : _handleAuth,
      isLoading: _isLoading,
      isFullWidth: true,
      variant: ModernButtonVariant.primary,
      icon: Icon(_isSignUp ? Icons.person_add : Icons.login),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'veya',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[400] 
                  : Colors.grey[600],
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        // Google Sign In
        ModernButton(
          text: 'Google ile Devam Et',
          onPressed: _isLoading ? null : _handleGoogleSignIn,
          variant: ModernButtonVariant.outline,
          isFullWidth: true,
          icon: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://developers.google.com/identity/images/g-logo.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Apple Sign In
        ModernButton(
          text: 'Apple ile Devam Et',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Apple girişi yakında eklenecek'),
                backgroundColor: AppColors.info,
              ),
            );
          },
          variant: ModernButtonVariant.outline,
          isFullWidth: true,
          icon: const Icon(Icons.apple, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildToggleAuth() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp ? 'Zaten hesabınız var mı? ' : 'Hesabınız yok mu? ',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[400] 
                : Colors.grey[600],
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isSignUp = !_isSignUp;
              _errorMessage = null;
            });
          },
          child: Text(
            _isSignUp ? 'Giriş Yap' : 'Üye Ol',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkipButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: widget.onSkip,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          'Şimdilik Geç',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }


}
