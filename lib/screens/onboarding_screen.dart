// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/onboarding_page_model.dart';
import '../services/onboarding_service.dart';
import '../design_system/widgets/modern_button.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  
  const OnboardingScreen({
    super.key,
    required this.onCompleted,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<OnboardingPageModel> _pages = OnboardingData.getPages();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _showLoginComingSoon();
  }

  void _completeOnboarding() async {
    await OnboardingService.completeOnboarding();
    widget.onCompleted();
  }

  void _showLoginComingSoon() {
    _completeOnboarding(); // Onboarding'i tamamla, main.dart auth screen'i gösterecek
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (hidden on last page)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage < _pages.length - 3) // Hide on last three pages
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'Geç',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_pages[index], index);
                },
              ),
            ),
            
            // Bottom section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildPageIndicator(index),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Login/Continue buttons for last page, Next button for others
                  if (_currentPage == _pages.length - 1) ...[
                    // Login button
                    SizedBox(
                      width: double.infinity,
                      child: ModernButton(
                        text: 'Oturum Aç',
                        onPressed: _showLoginComingSoon,
                        gradient: LinearGradient(
                          colors: _pages[_currentPage].gradientColors,
                        ),
                        icon: const Icon(Icons.login),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Continue without login button
                    SizedBox(
                      width: double.infinity,
                      child: ModernButton(
                        text: 'Oturum Açmadan Devam Et',
                        onPressed: _completeOnboarding,
                        variant: ModernButtonVariant.outline,
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ),
                  ] else ...[
                    // Next button for other pages
                    SizedBox(
                      width: double.infinity,
                      child: ModernButton(
                        text: 'Devam Et',
                        onPressed: _nextPage,
                        gradient: LinearGradient(
                          colors: _pages[_currentPage].gradientColors,
                        ),
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPageModel page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: page.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: page.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: Colors.white,
            ),
          )
          .animate(delay: Duration(milliseconds: index * 100))
          .scale(
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
          )
          .shimmer(
            duration: const Duration(milliseconds: 1200),
            color: Colors.white.withOpacity(0.3),
          ),
          
          const SizedBox(height: 50),
          
          // Title
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: page.title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black87,
                  ),
                ),
                TextSpan(
                  text: '\n${page.subtitle}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: page.gradientColors,
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                  ),
                ),
              ],
            ),
          )
          .animate(delay: Duration(milliseconds: index * 100 + 200))
          .fadeIn(duration: const Duration(milliseconds: 600))
          .slideY(
            begin: 0.3,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
          ),
          
          const SizedBox(height: 30),
          
          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[300] 
                  : Colors.grey[600],
            ),
          )
          .animate(delay: Duration(milliseconds: index * 100 + 400))
          .fadeIn(duration: const Duration(milliseconds: 600))
          .slideY(
            begin: 0.3,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    final page = _pages[_currentPage];
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isActive 
            ? page.primaryColor
            : (Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[600] 
                : Colors.grey[300]),
      ),
    );
  }
}