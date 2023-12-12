import os
import json
import requests
from flask import Flask, request, render_template_string

# Define constants from environment variables
API_URL = os.getenv('API_URL', 'https://api.openai.com/v1/completions')
API_KEY = os.getenv('API_KEY')  # Assumes API key is set as an environment variable
API_HEADERS = {
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {API_KEY}'
}
MODEL_NAME = os.getenv('MODEL_NAME', 'text-davinci-003')
TEMPERATURE = float(os.getenv('TEMPERATURE', '0.5'))
MAX_TOKENS = int(os.getenv('MAX_TOKENS', '1024'))

app = Flask(__name__)

def log_request_response(response, data):
    """Log the request and response data to the terminal."""
    print(f'Request URL: {response.request.url}')
    print(f'Request Headers: {response.request.headers}')
    print(f'Request JSON Body: {json.dumps(data, indent=4)}')
    print(f'Response Status Code: {response.status_code}')
    print(f'Response Headers: {response.headers}')
    print(f'Response JSON Body: {json.dumps(response.json(), indent=4)}')

def get_generated_text(prompt):
    """Send a request to the API and return the generated text."""
    data = {
        'model': MODEL_NAME,
        'prompt': prompt,
        'temperature': TEMPERATURE,
        'max_tokens': MAX_TOKENS
    }
    try:
        response = requests.post(API_URL, headers=API_HEADERS, json=data)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx and 5xx)
    except requests.RequestException as e:
        app.logger.error(f'Error sending request to API: {e}')
        return f'Error: Unable to communicate with the API. {str(e)}'
    
    log_request_response(response, data)  # Log the request and response data
    
    try:
        return response.json()['choices'][0]['text']
    except (ValueError, KeyError) as e:
        error_message = f'Error decoding JSON response or missing expected keys: {e}'
        app.logger.error(error_message)
        return f'Error: Unable to decode the server response. {str(e)}'

@app.route('/', methods=["GET", "POST"])
def index():
    if request.method == "POST":
        user_prompt = request.form['input_text']
        generated_text = get_generated_text(user_prompt)
        return render_template_string(html_content, generated_text=generated_text)
    return render_template_string(html_content)

# Embedding HTML content
html_content = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>My First ChatGPT</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <style>
        body { padding-top: 5rem; }
        .container { max-width: 600px; }
    </style>
</head>
<body>
<div class="container">
    <h1 class="text-center mb-4">Prompt Generator</h1>
    <form action="{{ url_for('index') }}" method="POST">
        <div class="mb-3">
            <label for="input_text" class="form-label">Enter your prompt:</label>
            <input type="text" class="form-control" name="input_text" placeholder="Ask a Question" required>
        </div>
        <button type="submit" class="btn btn-primary mb-3">Fire away!</button>
        {% if generated_text %}
        <div class="result">
            <h3 class="mt-4">Generated Text:</h3>
            <p>{{ generated_text }}</p>
        </div>
        {% endif %}
    </form>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
'''

if __name__ == '__main__':
    app.run()
