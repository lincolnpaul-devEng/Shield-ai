import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: OnboardingView(),
    );
  }
}

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int _currentPage = 0;

  void _nextPage() {
    setState(() {
      if (_currentPage < 2) {
        _currentPage++;
      }
    });
  }

  void _skipToLast() {
    setState(() {
      _currentPage = 2;
    });
  }

  void _getStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_onboarded', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _OnboardingPage(
        title: 'Stay Protected.',
        subtitle: 'Secure your mobile money with AI-powered fraud detection.',
        showNextButton: true,
        onNextPressed: _nextPage,
        currentPage: _currentPage,
      ),
      _OnboardingPage(
        title: 'How M-Pesa Max Works',
        subtitle: 'Our AI analyzes your transaction patterns in real-time, detecting suspicious activities and alerting you instantly. Stay one step ahead of fraudsters.',
        showNextButton: true,
        onNextPressed: _nextPage,
        currentPage: _currentPage,
      ),
      _OnboardingPage(
        title: 'Ready to Get Started?',
        subtitle: 'Join thousands of users who trust M-Pesa Max to protect their finances. Create your account now.',
        showNextButton: false,
        onGetStartedPressed: _getStarted,
        currentPage: _currentPage,
      ),
    ];

    return Stack(
      children: [
        // Background Glows
        const _BackgroundGlows(),

        // Main Content
        pages[_currentPage],

        // Skip Button
        if (_currentPage < 2) _SkipButton(onPressed: _skipToLast),
      ],
    );
  }
}

class _BackgroundGlows extends StatelessWidget {
  const _BackgroundGlows();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A9E32).withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A9E32).withOpacity(0.2),
                    blurRadius: 120,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF087F23).withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF087F23).withOpacity(0.2),
                    blurRadius: 100,
                    spreadRadius: 0,
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

class _SkipButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SkipButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      right: 24,
      child: TextButton(
        onPressed: onPressed,
        child: const Text(
          'Skip',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _GlobeAnimation extends StatefulWidget {
  const _GlobeAnimation();

  @override
  _GlobeAnimationState createState() => _GlobeAnimationState();
}

class _GlobeAnimationState extends State<_GlobeAnimation> with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -10 * math.sin(_floatController.value * 2 * math.pi)),
          child: RotationTransition(
            turns: _spinController,
            child: SizedBox(
              width: 320,
              height: 320,
              child: SvgPicture.string(
                _globeSvg,
                placeholderBuilder: (context) => const CircularProgressIndicator(),
              ),
            ),
          ),
        );
      },
    );
  }
}


class _BottomSheetContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showNextButton;
  final VoidCallback? onNextPressed;
  final VoidCallback? onGetStartedPressed;
  final int currentPage;

  const _BottomSheetContent({
    required this.title,
    required this.subtitle,
    required this.showNextButton,
    this.onNextPressed,
    this.onGetStartedPressed,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        border: Border(
          top: BorderSide(color: const Color(0xFF334155).withOpacity(0.5)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF0A9E32), Color(0xFF087F23)],
              ).createShader(bounds),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 18,
                fontWeight: FontWeight.w300,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _PaginationDots(currentPage: currentPage),
            const SizedBox(height: 32),
            if (showNextButton)
              _NextButton(onPressed: onNextPressed!)
            else
              _GetStartedButton(onPressed: onGetStartedPressed!),
          ],
        ),
      ),
    );
  }
}

class _PaginationDots extends StatelessWidget {
  final int currentPage;

  const _PaginationDots({required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          width: index == currentPage ? 32 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: index == currentPage
                ? const Color(0xFF0A9E32)
                : const Color(0xFF475569),
            borderRadius: BorderRadius.circular(4),
            boxShadow: index == currentPage
                ? [
                    BoxShadow(
                      color: const Color(0xFF0A9E32).withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showNextButton;
  final VoidCallback? onNextPressed;
  final VoidCallback? onGetStartedPressed;
  final int currentPage;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.showNextButton,
    this.onNextPressed,
    this.onGetStartedPressed,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        if (currentPage == 0) const _GlobeAnimation(),
        const Spacer(),
        _BottomSheetContent(
          title: title,
          subtitle: subtitle,
          showNextButton: showNextButton,
          onNextPressed: onNextPressed,
          onGetStartedPressed: onGetStartedPressed,
          currentPage: currentPage,
        ),
      ],
    );
  }
}

class _GetStartedButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _GetStartedButton({required this.onPressed});

  @override
  _GetStartedButtonState createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: const Color(0xFF0A9E32),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A9E32).withOpacity(0.4),
                  blurRadius: 20,
                ),
              ],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Shimmer Effect
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: Transform(
                        transform: Matrix4.skewX(-0.3)..translate(
                          -200.0 + 400.0 * _shimmerController.value,
                        ),
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Get Started',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    FaIcon(FontAwesomeIcons.arrowRight, color: Color(0xFF0F172A), size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NextButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: const Color(0xFF0A9E32),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A9E32).withOpacity(0.4),
                  blurRadius: 20,
                ),
              ],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                FaIcon(FontAwesomeIcons.arrowRight, color: Color(0xFF0F172A), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// SVG content for the globe
const String _globeSvg = '''
<svg viewBox="0 0 200 200">
  <defs>
    <radialGradient id="globeGradient" cx="50%" cy="50%" r="50%" fx="50%" fy="50%">
      <stop offset="0%" stop-color="#0f172a" stop-opacity="1" />
      <stop offset="100%" stop-color="#1e293b" stop-opacity="1" />
    </radialGradient>
    <linearGradient id="lineGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0A9E32" stop-opacity="0.1" />
      <stop offset="50%" stop-color="#0A9E32" stop-opacity="0.6" />
      <stop offset="100%" stop-color="#0A9E32" stop-opacity="0.1" />
    </linearGradient>
  </defs>

  <circle cx="100" cy="100" r="90" fill="url(#globeGradient)" stroke="#334155" stroke-width="1" />

  <g>
    <ellipse cx="100" cy="100" rx="30" ry="90" fill="none" stroke="url(#lineGradient)" stroke-width="1" class="opacity-50" />
    <ellipse cx="100" cy="100" rx="60" ry="90" fill="none" stroke="url(#lineGradient)" stroke-width="1" class="opacity-50" />
    <line x1="100" y1="10" x2="100" y2="190" stroke="url(#lineGradient)" stroke-width="1" />
    
    <ellipse cx="100" cy="100" rx="90" ry="30" fill="none" stroke="url(#lineGradient)" stroke-width="1" class="opacity-50" />
    <ellipse cx="100" cy="100" rx="90" ry="60" fill="none" stroke="url(#lineGradient)" stroke-width="1" class="opacity-50" />
    <line x1="10" y1="100" x2="190" y2="100" stroke="url(#lineGradient)" stroke-width="1" />

    <circle cx="100" cy="40" r="3" fill="#0A9E32" />
    <circle cx="160" cy="100" r="2" fill="#0A9E32" />
    <circle cx="40" cy="100" r="2" fill="#0A9E32" />
    <circle cx="130" cy="150" r="2.5" fill="#0A9E32" />
    <circle cx="70" cy="60" r="2.5" fill="#0A9E32" />
    
    <line x1="100" y1="40" x2="70" y2="60" stroke="#0A9E32" stroke-width="0.5" opacity="0.6" />
    <line x1="70" y1="60" x2="40" y2="100" stroke="#0A9E32" stroke-width="0.5" opacity="0.6" />
    <line x1="100" y1="40" x2="160" y2="100" stroke="#0A9E32" stroke-width="0.5" opacity="0.6" />
    <line x1="160" y1="100" x2="130" y2="150" stroke="#0A9E32" stroke-width="0.5" opacity="0.6" />
  </g>
  
  <circle cx="100" cy="100" r="98" fill="none" stroke="#0A9E32" stroke-width="1" stroke-dasharray="10 10" opacity="0.3" />
</svg>
''';