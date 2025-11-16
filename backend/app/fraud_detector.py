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

    def _fallback_response(self, message: str) -> Dict[str, Any]:
        # Deterministic conservative fallback
        return {
            'is_fraud': False,
            'confidence': 0.0,
            'action_required': False,
            'reason': f'Fallback: {message}',
        }
