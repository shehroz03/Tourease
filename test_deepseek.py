
import requests
import json

def test_deepseek_key():
    api_key = "sk-52bc3e9409de4d2fb843528bd78be28e"
    url = "https://api.deepseek.com/chat/completions"
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }
    
    payload = {
        "model": "deepseek-chat",
        "messages": [
            {"role": "system", "content": "You are a helpful assistant"},
            {"role": "user", "content": "Hi, are you working?"}
        ],
        "stream": False
    }
    
    print(f"Testing DeepSeek API Key: {api_key[:10]}...")
    
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=10)
        print(f"Status Code: {response.status_code}")
        if response.status_code == 200:
            print("Success! Response:")
            print(json.dumps(response.json(), indent=2))
            return True
        else:
            print("Error Response:")
            print(response.text)
            return False
    except Exception as e:
        print(f"Request failed: {e}")
        return False

if __name__ == "__main__":
    test_deepseek_key()
