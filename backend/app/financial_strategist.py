import os
import json
from typing import List, Dict, Any
import requests
from datetime import datetime

from .models import Transaction


class FinancialStrategist:
    def __init__(self):
        self.api_key = os.getenv('OPENROUTER_API_KEY')
        self.base_url = os.getenv('OPENROUTER_BASE_URL', 'https://openrouter.ai/api/v1/chat/completions')
        self.primary_model = os.getenv('OPENROUTER_MODEL', 'anthropic/claude-3-sonnet')
        self.fallback_model = os.getenv('OPENROUTER_FALLBACK_MODEL', 'google/gemini-flash-1.5')
        self.http_referer = os.getenv('OPENROUTER_HTTP_REFERER', 'http://localhost:5000')
        self.timeout_seconds = 20

    def ask_question(self, question: str, user_id: int, plan_data: Dict[str, Any] = None) -> str:
        """
        Answer a user's question about their financial plan using AI.
        """
        if not self.api_key:
            return "AI service is not configured. Please contact support."

        # Get user's recent transactions for context
        try:
            transactions = Transaction.history_for_user(user_id, limit=20)
            transactions_data = [tx.to_dict() for tx in transactions]
        except Exception:
            transactions_data = []

        prompt = self._build_conversation_prompt(question, plan_data or {}, transactions_data)

        # Try primary model first, then fallback
        for model in (self.primary_model, self.fallback_model):
            try:
                response = self._call_openrouter(model, prompt)
                parsed = self._parse_response(response)
                if parsed:
                    return parsed
            except Exception as e:
                print(f"Model {model} failed: {e}")
                continue

        return "I'm sorry, but I'm unable to answer your question right now. Please try again later."

    def _build_conversation_prompt(self, question: str, plan_data: Dict[str, Any], transactions: List[Dict[str, Any]]) -> str:
        plan_summary = f"""
Current Financial Plan:
- Weekly Budget: KSH {plan_data.get('weekly_budget', 'N/A')}
- Monthly Budget: KSH {plan_data.get('monthly_budget', 'N/A')}
- Financial Health Score: {plan_data.get('financial_health_score', 'N/A')}/100
"""

        if plan_data.get('categories'):
            plan_summary += "\nSpending Categories:\n"
            for cat in plan_data['categories']:
                plan_summary += f"- {cat['name']}: Allocated KSH {cat['allocated']}\n"

        recent_transactions = "\nRecent Transactions (Last 10):\n"
        for tx in transactions[:10]:
            recent_transactions += f"- {tx['timestamp'][:10]}: KSH {tx['amount']} to {tx['recipient']}\n"

        return f"""You are a financial advisor specializing in Kenyan M-Pesa users. Answer the user's question with 2-3 key actionable tips.

USER'S QUESTION: {question}

IMPORTANT: Keep your response under 80 words. Use bullet points. Be specific to Kenyan context and M-Pesa usage. Focus on practical, immediate actions."""

    def _call_openrouter(self, model: str, prompt: str) -> Dict[str, Any]:
        headers = {
            'Authorization': f'Bearer {self.api_key}',
            'HTTP-Referer': self.http_referer,
            'X-Title': 'Shield AI Financial Advisor',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        }

        payload = {
            'model': model,
            'messages': [
                {"role": "system", "content": "You are a helpful financial advisor. Provide clear, actionable advice."},
                {"role": "user", "content": prompt},
            ],
            'temperature': 0.3,
            'max_tokens': 150,
        }

        resp = requests.post(self.base_url, headers=headers, json=payload, timeout=self.timeout_seconds)
        if resp.status_code >= 400:
            raise RuntimeError(f"OpenRouter error {resp.status_code}: {resp.text[:200]}")

        return resp.json()

    def _parse_response(self, response: Dict[str, Any]) -> str:
        try:
            choices = response.get('choices') or []
            if choices and 'message' in choices[0]:
                content = choices[0]['message'].get('content', '').strip()
                return content if content else None
        except Exception:
            pass

        return None