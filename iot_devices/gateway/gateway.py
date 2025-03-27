from flask import Flask, request, jsonify
import os
import time
import random

try:
    import paho.mqtt.client as mqtt
    MQTT_AVAILABLE = True
except ImportError:
    MQTT_AVAILABLE = False

app = Flask(__name__)
devices = {
    "thermostat": {"id": "therm001", "ip": "192.168.98.10", "type": "thermostat"},
    "camera": {"id": "cam001", "ip": "192.168.98.11", "type": "camera"}
}

@app.route('/')
def index():
    return """
    <h1>IoT Gateway</h1>
    <p>Connected devices: %s</p>
    <form action="/api/ping" method="POST">
        <label for="ip">IP to ping:</label>
        <input type="text" id="ip" name="ip" value="192.168.98.10">
        <button type="submit">Ping</button>
    </form>
    """ % len(devices)

@app.route('/api/devices', methods=['GET'])
def get_devices():
    # Vulnerability: no authentication for sensitive info
    return jsonify(devices)

@app.route('/api/ping', methods=['POST'])
def ping_device():
    # Vulnerability: command injection
    ip = request.form.get('ip', '')
    if not ip:
        return jsonify({"error": "IP address required"}), 400
    
    # Command injection vulnerability
    result = os.popen(f"ping -c 1 {ip}").read()
    return jsonify({"result": result})

def start_mqtt_listener():
    if not MQTT_AVAILABLE:
        print("MQTT client not available. MQTT functions disabled.")
        return
    
    try:
        def on_connect(client, userdata, flags, rc):
            print(f"Connected to MQTT broker with result code {rc}")
            client.subscribe("home/#")
        
        def on_message(client, userdata, msg):
            print(f"Message received: {msg.topic} = {msg.payload}")
        
        client = mqtt.Client()
        client.on_connect = on_connect
        client.on_message = on_message
        client.connect("mqtt_broker", 1883, 60)
        client.loop_forever()
    except Exception as e:
        print(f"MQTT Error: {e}")

if __name__ == '__main__':
    if MQTT_AVAILABLE:
        import threading
        mqtt_thread = threading.Thread(target=start_mqtt_listener, daemon=True)
        mqtt_thread.start()
    
    app.run(host='0.0.0.0', port=5000, debug=True)
