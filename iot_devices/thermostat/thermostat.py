from flask import Flask, request, jsonify
import time
import random

try:
    import paho.mqtt.client as mqtt
    MQTT_AVAILABLE = True
except ImportError:
    MQTT_AVAILABLE = False

app = Flask(__name__)
current_temp = 22.5
target_temp = 23.0
auth_token = "insecure_fixed_token_12345"

def publish_temp():
    if not MQTT_AVAILABLE:
        return
    try:
        client = mqtt.Client()
        client.connect("mqtt_broker", 1883, 60)
        client.publish("home/thermostat/temperature", f'{{"temperature": {current_temp}}}')
        client.disconnect()
    except Exception as e:
        print(f"MQTT Error: {e}")

@app.route('/')
def index():
    return """
    <h1>Smart Thermostat</h1>
    <p>Current temperature: <span id="temp">%s</span>°C</p>
    <p>Target temperature: <span id="target">%s</span>°C</p>
    <script>
        setInterval(() => fetch('/api/temperature').then(r => r.json()).then(data => {
            document.getElementById('temp').textContent = data.current;
            document.getElementById('target').textContent = data.target;
        }), 5000);
    </script>
    """ % (current_temp, target_temp)

@app.route('/api/temperature', methods=['GET'])
def get_temperature():
    global current_temp
    # Simulate temperature variation
    current_temp += random.uniform(-0.2, 0.2)
    current_temp = round(current_temp, 1)
    publish_temp()
    return jsonify({"current": current_temp, "target": target_temp})

@app.route('/api/target', methods=['POST'])
def set_target():
    global target_temp
    # Vulnerability: no authentication/authorization check
    data = request.json
    if data and 'temperature' in data:
        try:
            temp = float(data.get('temperature', target_temp))
            # Limiter la température à des valeurs raisonnables
            if 0 <= temp <= 40:
                target_temp = temp
                return jsonify({"status": "success", "target": target_temp})
            else:
                return jsonify({"status": "error", "message": "Temperature must be between 0 and 40°C"}), 400
        except (ValueError, TypeError):
            return jsonify({"status": "error", "message": "Invalid temperature value"}), 400
    return jsonify({"status": "error", "message": "Invalid request format"}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
