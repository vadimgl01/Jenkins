import os
import json
import hmac
import hashlib
from flask import Flask, request, jsonify

# --- Configuration ---
# IMPORTANT: This should be a strong, random string that matches the 
# 'Secret' configured in your Git hosting platform's webhook settings.
WEBHOOK_SECRET = "myciwebhook"
WEBHOOK_PATH = '/webhook'

app = Flask(__name__)

# --- Utility Function for Security ---
# This is a custom check to securely compare the received token with the expected secret.
# NOTE: GitHub usually sends a SHA256 signature, but we'll stick to a simple 
# custom token check (X-Custom-Webhook-Token) to match the previous JS example.
def secure_compare(received_token, expected_token):
    """Securely compares two string tokens to prevent timing attacks."""
    if not received_token or not expected_token:
        return False
    # Using hmac.compare_digest for secure string comparison
    return hmac.compare_digest(received_token.encode('utf-8'), expected_token.encode('utf-8'))

@app.route(WEBHOOK_PATH, methods=['POST'])
def handle_webhook():
    print(f"\n--- Received POST request for {request.path} ---")

    # 1. Security Check: Validate the Custom Secret Token
    received_token = request.headers.get('X-Custom-Webhook-Token')

    if not secure_compare(received_token, WEBHOOK_SECRET):
        print('SECURITY ALERT: Invalid or missing webhook secret/token.')
        return jsonify({"message": "Forbidden: Invalid Secret"}), 403

    # Determine the type of event (GitHub uses 'X-GitHub-Event')
    github_event = request.headers.get('X-GitHub-Event', 'unknown')
    print(f"Event Type: {github_event}")

    # 2. Process the Payload
    try:
        payload = request.json
    except Exception as e:
        print(f"ERROR: Could not parse JSON payload: {e}")
        return jsonify({"message": "Invalid JSON payload"}), 400
    
    # --- CORE WEBHOOK LOGIC GOES HERE ---
    
    if github_event == 'push':
        # Safely access nested data using .get()
        ref = payload.get('ref', 'N/A')
        branch = ref.split('/')[-1] if ref.startswith('refs/heads/') else ref
        pusher = payload.get('pusher', {}).get('name', 'N/A')
        
        print(f"✅ Push event detected on branch: {branch} by {pusher}")
        # Example action: Trigger a deployment script
        # os.system(f"./deploy_script.sh {branch}") 
        
    elif github_event == 'pull_request':
        action = payload.get('action', 'N/A')
        pr_number = payload.get('number', 'N/A')
        
        print(f"📝 Pull Request #{pr_number} event: {action}")
        # Example action: Run linting/tests
        # os.system(f"./run_tests.sh {pr_number}")
        
    else:
        print(f"ℹ️ Unhandled event type: {github_event}")
        
    # --- END CORE LOGIC ---
    
    # 3. Send a success response
    return jsonify({"message": "Webhook received and processed."}), 200

if __name__ == '__main__':
    print(f"Webhook server starting up...")
    print(f"Listening on http://127.0.0.1:5000{WEBHOOK_PATH}")
    print("Remember to use ngrok to expose this port publicly for your Git platform.")
    app.run(host='0.0.0.0', port=5000, debug=True)