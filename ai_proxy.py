"""
Simple AI proxy for Google Generative AI (Text Bison / PaLM) - do NOT commit your API KEY.
Usage:
  set GOOGLE_API_KEY=your_key_here
  python -m venv .venv
  .venv\Scripts\pip install flask requests python-dotenv
  .venv\Scripts\python ai_proxy.py

Endpoint:
  POST /api/ai/chat
  Body: { "message": "Hello" }

Response:
  { "response": "AI reply text" }

Notes:
- This proxy keeps the Google API key on the server (env var). Do not expose keys in the client/app.
- Replace the GENERATE_URL if Google changes the REST API path for your project/region.
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import os
try:
    import requests
except Exception as e:
    requests = None
    _requests_import_error = str(e)

app = Flask(__name__)
CORS(app)

GOOGLE_API_KEY = os.environ.get('GOOGLE_API_KEY')
# Default model (text-bison is commonly available). Adjust to your model if needed.
GENAI_URL = 'https://generativelanguage.googleapis.com/v1beta2/models/text-bison:generate'

@app.route('/')
def index():
    if requests is None:
        return jsonify({'ok': False, 'message': 'AI proxy running but missing dependency: requests', 'hint': 'Run setup_ai_proxy.ps1 to install requirements'}), 500
    return jsonify({'ok': True, 'message': 'AI proxy running'})

@app.route('/api/ai/chat', methods=['POST'])
def chat():
    if not GOOGLE_API_KEY:
        return jsonify({'error': 'Server misconfigured: missing GOOGLE_API_KEY env var'}), 500

    if requests is None:
        return jsonify({'error': 'Server misconfigured: missing Python dependency "requests"', 'hint': 'Run setup_ai_proxy.ps1 to install requirements', 'import_error': _requests_import_error}), 500

    data = request.get_json() or {}
    message = data.get('message', '').strip()
    if not message:
        return jsonify({'error': 'message is required'}), 400

    # Build request according to Generative Language API (text-bison v1beta2 generate)
    payload = {
        'prompt': {
            'text': message
        },
        'temperature': 0.2,
        'maxOutputTokens': 512
    }

    try:
        resp = requests.post(f"{GENAI_URL}?key={GOOGLE_API_KEY}", json=payload, timeout=30)
        if resp.status_code != 200:
            return jsonify({'error': f'Google API error: {resp.status_code} {resp.text}'}), 502

        j = resp.json()
        # Extract text: depending on API version, the generated text might be in
        # j['candidates'][0]['output'] or j['output'][0]['content'] etc.
        text = None
        if 'candidates' in j and isinstance(j['candidates'], list) and len(j['candidates']) > 0:
            cand = j['candidates'][0]
            text = cand.get('content') or cand.get('output') or None
        elif 'output' in j and isinstance(j['output'], list) and len(j['output']) > 0:
            # Some responses place pieces in output
            parts = []
            for piece in j['output']:
                if isinstance(piece, dict):
                    if 'content' in piece: parts.append(piece['content'])
                    elif 'text' in piece: parts.append(piece['text'])
                elif isinstance(piece, str):
                    parts.append(piece)
            text = ' '.join(parts).strip()
        else:
            text = j.get('response') or j.get('text') or None

        if not text:
            # As a fallback, return entire JSON as string to help debugging
            return jsonify({'error': 'Could not parse Google response', 'raw': j}), 502

        return jsonify({'response': text})

    except requests.RequestException as e:
        return jsonify({'error': f'Failed to call Google API: {e}'}), 502

if __name__ == '__main__':
    port = int(os.environ.get('AI_PROXY_PORT', 8001))
    print(f'Starting AI proxy on http://0.0.0.0:{port}')
    app.run(host='0.0.0.0', port=port)
