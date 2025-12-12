import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shield AI Terms of Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              '1. Acceptance of Terms',
              'By downloading, installing, or using Shield AI ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use the App.',
            ),

            _buildSection(
              '2. Description of Service',
              'Shield AI is a mobile application that provides:\n\n'
              '• M-Pesa transaction monitoring and analysis\n'
              '• Fraud detection and security alerts\n'
              '• Financial advice and budgeting assistance\n'
              '• Job opportunity search and recommendations\n\n'
              'The App integrates with M-Pesa services and uses AI technology to provide personalized financial insights.',
            ),

            _buildSection(
              '3. User Eligibility',
              'To use Shield AI, you must:\n\n'
              '• Be at least 18 years old\n'
              '• Be a resident of Kenya\n'
              '• Have a valid M-Pesa account\n'
              '• Provide accurate and complete information during registration',
            ),

            _buildSection(
              '4. Account Registration and Security',
              '• You are responsible for maintaining the confidentiality of your account credentials\n'
              '• You must immediately notify us of any unauthorized use of your account\n'
              '• We reserve the right to suspend or terminate accounts that violate these Terms',
            ),

            _buildSection(
              '5. Service Usage and Limitations',
              '• The App is provided on a freemium basis with potential future premium features\n'
              '• Service availability may be affected by M-Pesa system maintenance or outages\n'
              '• We reserve the right to modify or discontinue features with reasonable notice\n'
              '• Financial advice provided by the App is for informational purposes only',
            ),

            _buildSection(
              '6. Financial Advice Disclaimer',
              'Shield AI provides general financial information and analysis. This is not:\n\n'
              '• Professional financial advice\n'
              '• Investment recommendations\n'
              '• Legal advice\n\n'
              'Always consult with qualified professionals for important financial decisions. Shield AI is not liable for financial losses resulting from the use of our analysis or recommendations.',
            ),

            _buildSection(
              '7. User Conduct',
              'You agree not to:\n\n'
              '• Use the App for any illegal or unauthorized purpose\n'
              '• Attempt to reverse engineer or modify the App\n'
              '• Share your account credentials with others\n'
              '• Upload malicious code or interfere with App functionality\n'
              '• Use the App to harass, abuse, or harm others',
            ),

            _buildSection(
              '8. Intellectual Property',
              '• Shield AI and its content are protected by copyright and trademark laws\n'
              '• You may not reproduce, distribute, or create derivative works without permission\n'
              '• User-generated content remains your property but you grant us license to use it for service improvement',
            ),

            _buildSection(
              '9. Privacy and Data Protection',
              'Your privacy is important to us. Please review our Privacy Policy for details on how we collect, use, and protect your data. By using Shield AI, you consent to our data practices as outlined in the Privacy Policy.',
            ),

            _buildSection(
              '10. Third-Party Services',
              'Shield AI integrates with:\n\n'
              '• M-Pesa services (subject to Safaricom terms)\n'
              '• AI providers for analysis and recommendations\n'
              '• Job search services for employment opportunities\n\n'
              'Your use of these services is subject to their respective terms and conditions.',
            ),

            _buildSection(
              '11. Termination',
              '• You may terminate your account at any time\n'
              '• We may terminate or suspend your account for violations of these Terms\n'
              '• Upon termination, your right to use the App ceases immediately\n'
              '• We may retain certain data as required by law or for legitimate business purposes',
            ),

            _buildSection(
              '12. Limitation of Liability',
              'Shield AI is provided "as is" without warranties. We are not liable for:\n\n'
              '• Direct, indirect, incidental, or consequential damages\n'
              '• Loss of profits, data, or business opportunities\n'
              '• Service interruptions or data loss\n'
              '• Third-party actions or content\n\n'
              'Our total liability shall not exceed the amount paid by you for the service.',
            ),

            _buildSection(
              '13. Indemnification',
              'You agree to indemnify and hold Shield AI harmless from any claims, damages, or expenses arising from your use of the App or violation of these Terms.',
            ),

            _buildSection(
              '14. Governing Law',
              'These Terms are governed by the laws of Kenya. Any disputes shall be resolved in the courts of Nairobi County.',
            ),

            _buildSection(
              '15. Changes to Terms',
              'We may update these Terms periodically. Continued use of the App after changes constitutes acceptance of the new Terms. We will notify users of significant changes.',
            ),

            _buildSection(
              '16. Contact Information',
              'For questions about these Terms, please contact us at:\n\n'
              'Email: support@paullincoln428@gmail.com\n'
              'Phone: +254 101 531 660\n'
              'Address: Nairobi, Kenya',
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                'By continuing to use Shield AI, you acknowledge that you have read, understood, and agree to these Terms of Service.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}