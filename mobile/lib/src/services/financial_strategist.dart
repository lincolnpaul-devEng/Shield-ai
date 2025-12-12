import '../models/financial_enhancements.dart';
import 'api_service.dart';

class FinancialStrategist {
  final ApiService _apiService;

  FinancialStrategist(this._apiService);

  /// Ask AI a question about financial planning
  Future<ConversationMessage> askQuestion(
    String question,
    String userId, {
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      final response = await _apiService.askAI(userId, question, conversationHistory: conversationHistory);

      return ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        question: response['question']?.toString() ?? question,
        answer: response['answer']?.toString() ?? 'I apologize, but I\'m unable to answer your question right now. Please try again later.',
        timestamp: DateTime.now(),
        isFromUser: false, // AI response, not from user
      );
    } catch (e) {
      return ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        question: question,
        answer: 'I apologize, but I\'m unable to answer your question right now. Please try again later.',
        timestamp: DateTime.now(),
        isFromUser: false, // AI response, not from user
      );
    }
  }
}