from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route("/")
def home():
    return "API Server"

@app.route("/api/user")
def user():
    return jsonify({"id": 1, "username": "admin"})

@app.route("/api/ping", methods=["POST"])
def ping():
    """
    Vulnérabilité intentionnelle d'injection de commande 
    à des fins pédagogiques
    """
    data = request.json
    if not data or "host" not in data:
        return jsonify({"error": "Host parameter required"}), 400
        
    import os
    cmd = f"ping -c 1 {data.get('host')}"
    return jsonify({"output": os.popen(cmd).read()})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
