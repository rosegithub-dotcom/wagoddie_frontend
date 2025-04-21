// screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:wagoddie_app/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Define the colors as constants
  static const Color primaryOrange = Color.fromARGB(255, 235, 128, 6);
  static const Color lightYellow = Color(0xFFFFFACD);

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Welcome to Wagoddie Shoppers',
      description: 'Explore a Variety of Products\nand discover Your Next Stocks',
      imagePath: 'assets/images/rice.png',
      iconColor: const Color(0xFF3B82F6),
    ),
    OnboardingData(
      title: 'Track Your Orders With Ease',
      description: 'Monitor all your Customers Favourates\nto Stock all their Desired Products',
      imagePath: 'assets/images/cleaning.png',
      iconColor: const Color(0xFF0EA5E9),
    ),
    OnboardingData(
      title: 'Shop Now',
      description: 'Find Your Perfect Shop Products \ntoday',
      imagePath: 'assets/images/cookingoil.png',
      iconColor: const Color(0xFF10B981),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _skipToLastPage() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index]);
                    },
                  ),
                ),
                _buildBottomSection(),
                const SizedBox(height: 30),
              ],
            ),
            // Skip text in top right corner
            Positioned(
              top: 20,
              right: 20,
              child: _currentPage < _pages.length - 1 
                ? GestureDetector(
                    onTap: _skipToLastPage,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryOrange,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
        children: [
          const SizedBox(height: 80),
          // Image - increased size and removed background color
          Image.asset(
            data.imagePath,
            width: 1000,
            height: 250,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 40), // Increased spacing to push text down
          // Title - centered
          Text(
            data.title,
            textAlign: TextAlign.center, // Center align the title
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          // Description - already centered
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          // Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => _buildDot(index),
            ),
          ),
          const SizedBox(height: 30),
          // Next or Get Started button with updated colors
          SizedBox(
            width: 180,
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage < _pages.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  // Navigate to create account screen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange, // Updated color
                foregroundColor: lightYellow, // Updated text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: _currentPage == index ? 10 : 8,
      height: _currentPage == index ? 10 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index
            ? primaryOrange // Updated to use the primaryOrange color
            : const Color(0xFFCBD5E1),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String imagePath;
  final Color iconColor;

  OnboardingData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.iconColor,
  });
}
