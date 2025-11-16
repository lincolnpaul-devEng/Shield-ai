import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.attach_money,
      title: 'Sync Your M-Pesa',
      description: 'Connect securely to analyze your transactions and spot patterns. We only read M-Pesa messages to protect you.',
      color: Color(0xFF1E6DF0),
    ),
    OnboardingPage(
      icon: Icons.security,
      title: 'Fraud Protection',
      description: 'Get instant alerts for suspicious transactions before you lose money. We use AI to detect unusual activity.',
      color: Color(0xFF00B894),
    ),
    OnboardingPage(
      icon: Icons.insights,
      title: 'Smart Spending',
      description: 'AI-powered insights to help you save more and spend wisely. See exactly where your money goes.',
      color: Color(0xFFFF6B6B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                return _buildPage(_pages[index]);
              },
            ),
          ),
          _buildIndicator(),
          _buildButtons(context),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      color: page.color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 80, color: Colors.white),
          SizedBox(height: 32),
          Text(
            page.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              page.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _pages.asMap().entries.map((entry) {
          return Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPage == entry.key ? Color(0xFF1E6DF0) : Colors.grey[300],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () {
                _controller.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              },
              child: Text('Back', style: TextStyle(color: Color(0xFF1E6DF0))),
            ),
          Spacer(),
          ElevatedButton(
            onPressed: () {
              if (_currentPage == _pages.length - 1) {
                // Complete onboarding and go to permissions
                Navigator.pushReplacementNamed(context, '/permissions');
              } else {
                _controller.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1E6DF0),
              foregroundColor: Colors.white,
            ),
            child: Text(
              _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}