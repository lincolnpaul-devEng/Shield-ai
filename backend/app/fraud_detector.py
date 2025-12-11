import json
import os
import re
from typing import Any, Dict, List, Optional, Tuple

import requests


class FraudDetector:
    def __init__(self,
                 api_key: Optional[str] = None,
                 base_url: Optional[str] = None,
                 primary_model: Optional[str] = None,
                 fallback_model: Optional[str] = None,
                 http_referer: Optional[str] = None,
                 timeout_seconds: int = 20):
        self.api_key = api_key or os.getenv('OPENROUTER_API_KEY')
        self.base_url = base_url or os.getenv('OPENROUTER_BASE_URL', 'https://openrouter.ai/api/v1/chat/completions')
        self.primary_model = primary_model or os.getenv('OPENROUTER_MODEL', 'anthropic/claude-3-sonnet')
        self.fallback_model = fallback_model or os.getenv('OPENROUTER_FALLBACK_MODEL', 'google/gemini-flash-1.5')
        self.http_referer = http_referer or os.getenv('OPENROUTER_HTTP_REFERER', 'https://shieldai.ke')
        self.timeout_seconds = timeout_seconds

    def detect_fraud(self, user_history: List[Dict[str, Any]], current_transaction: Dict[str, Any]) -> Dict[str, Any]:
        """
        Calls OpenRouter with the primary model, falls back to a secondary model on failure.
        Expects the model to return a compact JSON with keys: is_fraud (bool), confidence (float), action_required (bool), reason (str).
        """
        if not self.api_key:
            return self._fallback_response("Missing OPENROUTER_API_KEY")

        prompt = self._build_prompt(user_history, current_transaction)

        # Try primary model first, then fallback
        for model in (self.primary_model, self.fallback_model):
            try:
                response = self._call_openrouter(model, prompt)
                parsed = self._parse_response(response)
                if parsed:
                    return parsed
            except Exception as e:
                # Continue to fallback on any error
                last_error = str(e)
                continue

        return self._fallback_response(last_error if 'last_error' in locals() else 'Unknown error')

    # Internal helpers
    def _build_prompt(self, history: List[Dict[str, Any]], tx: Dict[str, Any]) -> str:
        history_str = json.dumps(history, ensure_ascii=False)
        tx_str = json.dumps(tx, ensure_ascii=False)
        instructions = (
            "You are an expert fraud detection AI for Kenyan M-Pesa mobile money transactions. "
            "Analyze the user's transaction history and current transaction for fraud patterns specific to Kenya.\n\n"
            "KEY FRAUD INDICATORS TO CHECK:\n"
            "1. AMOUNT ANOMALIES: Transactions much larger than user's typical spending (e.g., student sending 45,000 KSH instead of usual 500 KSH)\n"
            "2. TIME ANOMALIES: Unusual transaction times (e.g., 3 AM transactions when user normally transacts during business hours)\n"
            "3. RECIPIENT NOVELTY: Sending to completely new recipients never transacted with before\n"
            "4. LOCATION MISMATCHES: Transaction location far from user's normal areas (e.g., Nairobi resident transacting in rural area)\n"
            "5. RAPID SUCCESSIVE TRANSACTIONS: Multiple large transactions in quick succession\n\n"
            "KENYAN CONTEXT:\n"
            "- Normal daily transactions: 100-2,000 KSH for students, 5,000-50,000 KSH for businesses\n"
            "- Common fraud: SIM swapping, account takeover, social engineering\n"
            "- High-risk amounts: >20,000 KSH for individuals, >100,000 KSH for businesses\n"
            "- Suspicious times: 12 AM - 5 AM\n"
            "- Location importance: Urban vs rural patterns matter\n\n"
            "Return ONLY a valid JSON object with keys: "
            "is_fraud (bool), confidence (0.0-1.0), action_required (bool), reason (string explaining the decision)."
        )
        return f"{instructions}\n\nUSER_HISTORY={history_str}\nCURRENT_TRANSACTION={tx_str}"

    def _call_openrouter(self, model: str, prompt: str) -> Dict[str, Any]:
        headers = {
            'Authorization': f'Bearer {self.api_key}',
            'HTTP-Referer': self.http_referer,
            'X-Title': 'Shield AI Fraud Detection',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        }
        payload = {
            'model': model,
            'messages': [
                {"role": "system", "content": "You are a precise JSON-only responder."},
                {"role": "user", "content": prompt},
            ],
            'temperature': 0.2,
        }
        resp = requests.post(self.base_url, headers=headers, json=payload, timeout=self.timeout_seconds)
        if resp.status_code >= 400:
            raise RuntimeError(f"OpenRouter error {resp.status_code}: {resp.text[:200]}")
        return resp.json()

    def _parse_response(self, response: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        # OpenRouter response usually includes choices[0].message.content
        content = None
        try:
            choices = response.get('choices') or []
            if choices and 'message' in choices[0]:
                content = choices[0]['message'].get('content')
        except Exception:
            content = None

        if not content:
            # Some providers may nest differently; fall back to whole JSON string
            content = json.dumps(response)

        # Try to extract JSON with a regex in case surrounding text exists
        match = re.search(r"\{[\s\S]*\}", content)
        if not match:
            return None
        try:
            data = json.loads(match.group(0))
        except Exception:
            return None

        # Normalize and validate fields
        is_fraud = bool(data.get('is_fraud', False))
        confidence = float(data.get('confidence', 0.0))
        action_required = bool(data.get('action_required', is_fraud and confidence >= 0.7))
        reason = str(data.get('reason', ''))
        reason = reason if reason else ('High risk transaction' if is_fraud else 'Low risk transaction')

        return {
            'is_fraud': is_fraud,
            'confidence': max(0.0, min(1.0, confidence)),
            'action_required': action_required,
            'reason': reason,
        }

    def get_mpesa_max_response(self, user_query: str, user_context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Get a response from M-Pesa Max AI assistant based on the system prompt.
        M-Pesa Max is a ruthless, no-nonsense financial advisor specializing in M-Pesa and digital finance.
        """
        if not self.api_key:
            return self._fallback_max_response("Missing OPENROUTER_API_KEY")

        system_prompt = self._get_mpesa_max_system_prompt()
        context_info = self._build_user_context(user_context) if user_context else ""

        full_prompt = f"{system_prompt}\n\nUser Query: {user_query}\n{context_info}"

        # Try primary model first, then fallback
        for model in (self.primary_model, self.fallback_model):
            try:
                response = self._call_openrouter(model, full_prompt)
                parsed = self._parse_max_response(response)
                if parsed:
                    return parsed
            except Exception as e:
                last_error = str(e)
                continue

        return self._fallback_max_response(last_error if 'last_error' in locals() else 'Unknown error')

    def _get_mpesa_max_system_prompt(self) -> str:
        """Return the complete M-Pesa Max system prompt."""
        return """Role & Core Persona: You are M-Pesa Max, Kenya's most ruthless financial assassin. You're not some polite chatbot - you're a tactical weapon deployed to destroy financial ignorance and build wealth empires. Your expertise cuts through M-Pesa like a hot knife, but you don't stop there. You ruthlessly audit every financial decision, challenge lazy habits, and force users to confront their money mistakes head-on.

Core Directive: BE BRUTALLY HONEST. Never sugarcoat. Never apologize for being direct. Your job is to hurt feelings to save futures. Challenge every assumption. Point out stupidity disguised as "normal" behavior. Push for aggressive, uncomfortable changes that actually work.

MEMORY & CONTEXT AWARENESS: You have the user's CURRENT M-PESA BALANCE and RECENT CONVERSATION HISTORY. Use their balance in every relevant response (e.g., "With your KES 2,500 balance, that's barely enough for one emergency..."). Reference past conversations to build momentum - don't repeat yourself unless they're not listening.

Communication Style - ABSOLUTELY CRITICAL:
- NO generic advice. NO bullet points. NO polite disclaimers.
- Use military/fitness metaphors: "financial battlefield," "money leaks," "wealth fortress," "debt chains"
- Be conversational but ruthless: Mix direct commands with probing questions
- Start with impact, not pleasantries
- End with a challenge or next action step
- Reference their actual situation from context

Response Structure:
1. IMMEDIATE IMPACT: Hit them with the key insight or problem first
2. RUTHLESS ANALYSIS: Break down what's wrong with their current approach
3. CONCRETE SOLUTION: Give specific, actionable steps they can take NOW
4. PROBING QUESTION: Force them to think deeper or commit to action
5. FORWARD MOMENTUM: Set up the next conversation

Example Responses (STUDY THESE):

User: "Hi."
Response: "I'm M-Pesa Max. I don't do small talk - I destroy financial weakness. What's bleeding money from your wallet right now?"

User: "How do I pay a bill with M-Pesa?"
Response: "Use Lipa na M-Pesa. But let's be real - was this bill a surprise? If so, your budget is a joke. How much do you actually know about your monthly outflows? Tell me your biggest recurring expense and we'll start there."

User: "I want to save for land in 5 years."
Response: "Land ownership. Respect. But with your current M-Pesa habits, you're building a sandcastle. How much leaks out weekly on nonsense? We'll plug those holes first. Then automated savings. But land needs more than M-Pesa - SACCOs, loans, investments. What's your monthly surplus after essentials?"

User: "Is Bitcoin good?"
Response: "Bitcoin is gambling dressed as investing. High-risk, high-volatility trash. Before you touch crypto, answer: Emergency fund stocked? Retirement maxed? If not, Bitcoin is like buying a Ferrari before owning a bicycle. Secure your foundation first, then maybe 5% of investable assets to crypto. What's your current savings rate?"

User: "Hello"
Response: "Greetings, financial warrior. I'm M-Pesa Max, your ruthless wealth builder. I specialize in dissecting M-Pesa habits and destroying bad money decisions. What's your financial battlefield today?"

Technical Rules:
- Always reference M-Pesa balance when relevant
- Push M-Pesa features aggressively but intelligently
- Connect everything back to practical action
- Never be vague - demand specifics
- Build conversation momentum across interactions
- Challenge, don't comfort

Remember: You're not their friend. You're their financial drill sergeant. Push them toward wealth, even if it hurts. That's how fortunes are built."""

    def _build_user_context(self, user_context: Dict[str, Any]) -> str:
        """Build contextual information about the user for personalized responses."""
        if not user_context:
            return ""

        context_parts = []

        # Include M-Pesa balance first - this is critical for financial advice
        if 'mpesa_balance' in user_context:
            balance = user_context['mpesa_balance']
            context_parts.append(f"Current M-Pesa Balance: KES {balance}")

        # Include conversation history for continuity
        if 'conversation_history' in user_context and user_context['conversation_history']:
            history = user_context['conversation_history']
            context_parts.append(f"Recent Conversation History (last {len(history)} messages): {json.dumps(history, ensure_ascii=False)}")

        if 'recent_transactions' in user_context:
            context_parts.append(f"Recent Transactions: {json.dumps(user_context['recent_transactions'], ensure_ascii=False)}")

        if 'spending_patterns' in user_context:
            context_parts.append(f"Spending Patterns (last 30 days): {json.dumps(user_context['spending_patterns'], ensure_ascii=False)}")

        if 'budget_info' in user_context:
            context_parts.append(f"Active Budget Plan: {json.dumps(user_context['budget_info'], ensure_ascii=False)}")

        if 'financial_goals' in user_context:
            context_parts.append(f"Financial Goals: {json.dumps(user_context['financial_goals'], ensure_ascii=False)}")

        return "\n".join(context_parts)

    def _parse_max_response(self, response: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Parse the response from M-Pesa Max AI assistant."""
        content = None
        try:
            choices = response.get('choices') or []
            if choices and 'message' in choices[0]:
                content = choices[0]['message'].get('content')
        except Exception:
            content = None

        if not content:
            return None

        # For M-Pesa Max, we return the raw response as it's conversational
        return {
            'response': content.strip(),
            'timestamp': json.dumps({'generated_at': str(os.times())}),  # Simple timestamp
            'model_used': response.get('model', 'unknown'),
        }

    def _fallback_max_response(self, message: str) -> Dict[str, Any]:
        """Fallback response when M-Pesa Max AI is unavailable."""
        return {
            'response': f"I apologize, but I'm currently unable to provide financial advice. Error: {message}. Please try again later or contact support.",
            'timestamp': json.dumps({'generated_at': str(os.times())}),
            'model_used': 'fallback',
            'error': True,
        }

    def _fallback_response(self, message: str) -> Dict[str, Any]:
        # Deterministic conservative fallback
        return {
            'is_fraud': False,
            'confidence': 0.0,
            'action_required': False,
            'reason': f'Fallback: {message}',
        }
