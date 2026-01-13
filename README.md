# tourease

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## AI Chat (Google Generative AI)

This repo includes a small server-side proxy (`ai_proxy.py`) that forwards chat prompts to Google Generative AI (PaLM/text-bison). This is intentionally server-side so you do not embed API keys in the Flutter app.

Quick steps:
- Install requirements: `pip install -r requirements_ai.txt`
- Set env var: `set GOOGLE_API_KEY=YOUR_KEY` (PowerShell) or use a secret manager
- Run: `python ai_proxy.py` (proxy listens on port 8001 by default)
- From Flutter, `AiService.ask(prompt)` will call the proxy (default base URL is `http://192.168.1.27:8001`). Use `--dart-define=AI_PROXY_URL=http://HOST:8001` to override.

Security: do not commit API keys. Use environment variables, secret managers, or server-side restrictions in production.
