import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shield AI Privacy Policy',
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
              '1. Introduction',
              'Shield AI ("we", "us", or "our") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
            ),

            _buildSection(
              '2. Information We Collect',
              'We collect the following types of information:\n\n'
              '• Phone numbers for account identification and M-Pesa integration\n'
              '• Transaction data from M-Pesa for analysis and fraud detection\n'
              '• Location data to detect unusual transaction patterns\n'
              '• App usage data for service improvement\n'
              '• Device information for security and compatibility',
            ),

            _buildSection(
              '3. How We Use Your Information',
              'Your information is used to:\n\n'
              '• Provide M-Pesa transaction monitoring and analysis\n'
              '• Detect and prevent fraudulent activities\n'
              '• Offer personalized financial advice and insights\n'
              '• Search for relevant job opportunities\n'
              '• Improve app functionality and user experience\n'
              '• Ensure compliance with Kenyan regulations',
            ),

            _buildSection(
              '4. Data Storage and Security',
              '• All data is stored in secure cloud PostgreSQL databases\n'
              '• Sensitive information (names, phone numbers) is encrypted\n'
              '• M-Pesa PINs are never stored or processed\n'
              '• Data retention is limited to 90 days\n'
              '• Regular security audits and updates are performed',
            ),

            _buildSection(
              '5. Data Sharing and Third Parties',
              'We do not share your personal data with third parties except:\n\n'
              '• As required by law or regulatory authorities\n'
              '• With your explicit consent\n'
              '• For essential service operations (anonymized and aggregated)\n'
              '• With M-Pesa/Safaricom for transaction processing',
            ),

            _buildSection(
              '6. Your Rights Under Kenyan Law',
              'Under the Data Protection Act 2019, you have the right to:\n\n'
              '• Access your personal data we hold\n'
              '• Request correction of inaccurate data\n'
              '• Request deletion of your data\n'
              '• Withdraw consent for data processing\n'
              '• Data portability in machine-readable format\n'
              '• Lodge complaints with the Office of the Data Protection Commissioner',
            ),

            _buildSection(
              '7. Cookies and Tracking',
              'Shield AI may use minimal tracking for:\n\n'
              '• App performance monitoring\n'
              '• Crash reporting and debugging\n'
              '• Usage analytics (anonymized)\n\n'
              'You can control tracking preferences in your device settings.',
            ),

            _buildSection(
              '8. Children\'s Privacy',
              'Shield AI is not intended for children under 18. We do not knowingly collect personal information from children. If we become aware of such collection, we will delete the information immediately.',
            ),

            _buildSection(
              '9. International Data Transfers',
              'Your data may be processed in Kenya or other jurisdictions with adequate data protection standards. We ensure all transfers comply with Kenyan data protection laws.',
            ),

            _buildSection(
              '10. Data Breach Notification',
              'In the event of a data breach, we will:\n\n'
              '• Notify affected users within 72 hours\n'
              '• Report to the Office of the Data Protection Commissioner\n'
              '• Take immediate steps to contain and mitigate the breach\n'
              '• Provide guidance on protective measures',
            ),

            _buildSection(
              '11. Changes to This Privacy Policy',
              'We may update this Privacy Policy periodically. Significant changes will be communicated through:\n\n'
              '• In-app notifications\n'
              '• Email communications\n'
              '• Updates to this policy document\n\n'
              'Continued use of Shield AI after changes constitutes acceptance.',
            ),

            _buildSection(
              '12. Contact Information',
              'For privacy-related inquiries, please contact our Data Protection Officer:\n\n'
              'Email: privacy@shieldai.co.ke\n'
              'Phone: +254 715 996 213\n'
              'Address: Nairobi, Kenya\n\n'
              'Office of the Data Protection Commissioner:\n'
                        'Email: info@odpc.go.ke\n'
                        'Phone: +254 20 271 6200',
                  ),
                        ],
                      ),
                    ),
                  );
                }
              
                Widget _buildSection(String title, String content) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
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
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }
              
