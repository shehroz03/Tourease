AI integration (Google Generative AI)

Overview
- This project includes a small server-side proxy `ai_proxy.py` which accepts POST /api/ai/chat and forwards prompts to Google Generative Language API using a server-side API key. Keep the key out of client code and do not commit it to version control.

Setup (local dev)
1. Create a Python virtual env and activate it (Windows PowerShell):
   python -m venv .venv; .venv\Scripts\Activate.ps1
2. Install dependencies:
   pip install -r requirements_ai.txt
3. Set your Google API key (PowerShell):
   $env:GOOGLE_API_KEY = 'AIzaSy...'
   (do NOT commit this value)
4. Run the proxy:
   .venv\Scripts\python.exe ai_proxy.py

Helper script:
- Run `./setup_ai_proxy.ps1` in PowerShell to create a venv and install dependencies automatically. This will install `requests` so VS Code's Pylance stops warning about the missing module.

Helper extension (auto-reload)
- This repo includes a tiny developer extension under `.vscode/extensions/tourease-auto-reload` that watches for `.ai_proxy_setup_done` and reloads the window when created.
- The setup helper (`./setup_ai_proxy.ps1`) creates `.ai_proxy_setup_done` on success and will attempt to auto-install the extension using the `code` CLI if available.


Usage from Flutter
- The client code uses `AiService.ask(prompt)` which calls `http://192.168.1.27:8001/api/ai/chat` by default.
- You can override the base URL at build time using Dart define:
  flutter run -d chrome --dart-define=AI_PROXY_URL=http://YOUR_HOST:8001

Security notes
- Never store or commit raw API keys in the repository.
- In production, use a secret manager and restrict the API key to the necessary services/IPs.

Troubleshooting
- If you get a 500 from the proxy, ensure `GOOGLE_API_KEY` environment variable is set.
- If Google returns a 4xx/5xx error, the proxy will forward the error text to help debugging.
