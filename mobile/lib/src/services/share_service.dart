import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> shareMessage(BuildContext context, String message) async {
    try {
      // Format the message for sharing
      final formattedMessage = 'M-Pesa Max Financial Advice:\n\n$message\n\nShared from M-Pesa Max';

      await Share.share(
        formattedMessage,
        subject: 'M-Pesa Max Financial Advice',
      );
    } catch (e) {
      // Show error feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to share message'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}