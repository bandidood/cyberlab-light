#!/bin/bash

echo "
   ______      __            __        __    __  ______ __  __     
  / ____/_  __/ /_  ___     / /       / /   / / / /_  _// /_/ /_    
 / /   / / / / __ \/ _ \   / /  _____/ /   / / / / / / / __/ __ \   
/ /___/ /_/ / /_/ /  __/  / /__/____/ /___/ /_/ / / / / /_/ / / /   
\____/\__, /_.___/\___/  /_____/   /_____/\____/ /_/  \__/_/ /_/    
     /____/                                                         

Laboratoire de cybersécurité léger et modulaire - Script de configuration
"

# Vérifier les prérequis
echo "🔍 Vérification des prérequis..."

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Veuillez installer Docker avant de continuer."
    exit 1
fi

# Vérifier si Docker Compose est installé
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé. Veuillez installer Docker Compose avant de continuer."
    exit 1
fi

echo "✅ Docker et Docker Compose sont installés."

# Création de la structure de base
echo "📁 Création de la structure de répertoires..."

# Répertoires principaux
mkdir -p shared_files \
         snort/rules \
         snort/log \
         mqtt/config \
         mqtt/data \
         mqtt/log \
         vuln_bank_app \
         vuln_web_server \
         iot_devices/thermostat \
         iot_devices/gateway \
         nginx_backend/html \
         api_backend \
         haproxy \
         filebeat

# Configuration Mosquitto (MQTT)
echo "🔧 Configuration du broker MQTT..."
cat > mqtt/config/mosquitto.conf << 'EOF'
listener 1883
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
EOF

# Configuration HAProxy
echo "🔧 Configuration de HAProxy..."
cat > haproxy/haproxy.cfg << 'EOF'
global
    log stdout format raw local0
    chroot /var/lib/haproxy
    stats socket /var/run/haproxy.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # Configuration TLS vulnérable
    tune.ssl.default-dh-param 1024

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000

# Interface d'administration avec vulnérabilité de configuration
frontend stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats admin if TRUE  # Vulnérabilité: accès admin sans authentification

# Frontend principal pour HTTP
frontend http_front
    bind *:80
    
    # Vulnérabilité: En-têtes HTTP non sécurisés
    http-response set-header X-Powered-By HAProxy
    http-response set-header Server HAProxy

    # Routage
    acl is_api path_beg /api
    use_backend api_servers if is_api
    default_backend web_servers

# Backend pour serveurs web
backend web_servers
    balance roundrobin
    option httpchk GET /
    http-check expect status 200
    
    # Sticky sessions vulnérables (basées sur IP)
    stick-table type ip size 200k expire 30m
    stick on src

    # Serveurs backend
    server web1 backend1:80 check
    server web2 backend2:80 check

# Backend pour API
backend api_servers
    balance leastconn  # Équilibrage basé sur les connexions
    option httpchk GET /
    http-check expect status 200
    
    # Vulnérabilité: pas de vérification TLS pour le backend
    server api1 api_backend:5000 check
EOF

# Configuration de l'application thermostat IoT
echo "🔧 Configuration de l'application thermostat IoT..."
cat > iot_devices/thermostat/thermostat.py << 'EOF'
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
EOF

# Configuration de passerelle IoT
echo "🔧 Configuration de la passerelle IoT..."
cat > iot_devices/gateway/gateway.py << 'EOF'
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
EOF

# Configuration API Backend
echo "🔧 Configuration de l'API backend..."
cat > api_backend/app.py << 'EOF'
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
EOF

# Configuration de l'application bancaire vulnérable simplifiée
echo "🔧 Configuration de l'application bancaire vulnérable..."
cat > vuln_bank_app/index.php << 'EOF'
<?php
session_start();
?>
<!DOCTYPE html>
<html>
<head>
    <title>SecureBank - Votre banque en ligne</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4; }
        header { background-color: #2c3e50; color: white; padding: 1em; text-align: center; }
        .container { width: 80%; margin: 0 auto; padding: 2em; }
        .login-form { background-color: white; padding: 2em; border-radius: 5px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        input[type=text], input[type=password] { width: 100%; padding: 12px 20px; margin: 8px 0; display: inline-block; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; }
        button { background-color: #2c3e50; color: white; padding: 14px 20px; margin: 8px 0; border: none; border-radius: 4px; cursor: pointer; width: 100%; }
        button:hover { opacity: 0.8; }
    </style>
</head>
<body>
    <header>
        <h1>SecureBank</h1>
    </header>
    <div class="container">
        <div class="login-form">
            <h2>Connexion</h2>
            <?php
            // Simulation d'injection SQL
            if ($_SERVER['REQUEST_METHOD'] === 'POST') {
                $username = $_POST['username'] ?? '';
                $password = $_POST['password'] ?? '';
                
                // Vulnérabilité simulée: pas de base de données réelle pour économiser les ressources
                if (($username === 'admin' && $password === 'password') || 
                    ($username === "admin' --" && $password === "anything") ||
                    ($username === "user" && $password === "password123")) {
                    
                    $_SESSION['user_id'] = 1;
                    $_SESSION['username'] = $username;
                    echo "<p style='color: green;'>Connexion réussie ! Bienvenue " . htmlspecialchars($username) . "</p>";
                } else {
                    echo "<p style='color: red;'>Identifiants incorrects.</p>";
                }
            }
            ?>
            <form method="post" action="">
                <label for="username">Nom d'utilisateur:</label>
                <input type="text" id="username" name="username" required>
                <label for="password">Mot de passe:</label>
                <input type="password" id="password" name="password" required>
                <button type="submit">Se connecter</button>
            </form>
            <p><small>Indice: essayez 'admin' -- ' comme nom d'utilisateur</small></p>
        </div>
    </div>
</body>
</html>
EOF

# Configuration du serveur web vulnérable simplifié
echo "🔧 Configuration du serveur web vulnérable..."
cat > vuln_web_server/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Serveur Web Vulnérable</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; }
        h1 { color: #333; }
        .container { max-width: 800px; margin: 0 auto; }
        .card { background: #f9f9f9; border: 1px solid #ddd; border-radius: 5px; padding: 15px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Serveur Web Vulnérable</h1>
        
        <div class="card">
            <h2>Recherche</h2>
            <form action="search.php" method="GET">
                <input type="text" name="q" placeholder="Rechercher...">
                <button type="submit">Rechercher</button>
            </form>
        </div>
        
        <div class="card">
            <h2>Upload de fichier</h2>
            <form action="upload.php" method="POST" enctype="multipart/form-data">
                <input type="file" name="file">
                <button type="submit">Envoyer</button>
            </form>
        </div>
        
        <div class="card">
            <h2>Pages disponibles</h2>
            <ul>
                <li><a href="about.html">À propos</a></li>
                <li><a href="admin/">Administration</a></li>
                <li><a href="backup/.htaccess">Configuration</a></li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Configuration du backend nginx pour l'équilibreur de charge
echo "🔧 Configuration des backends Nginx..."
cat > nginx_backend/backend1.conf << 'EOF'
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    # Vulnérabilité: traversée de répertoire
    location /files/ {
        alias /usr/share/nginx/html/;
    }

    # Point de contrôle pour HAProxy
    location /health {
        return 200 "OK\n";
    }
}
EOF

cat > nginx_backend/backend2.conf << 'EOF'
server {
    listen 80;
    server_name localhost;

    # Vulnérabilité: CORS trop permissif
    add_header 'Access-Control-Allow-Origin' '*';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, DELETE, PUT';
    add_header 'Access-Control-Allow-Headers' '*';

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    # Vulnérabilité: exposition de logs
    location /logs/ {
        autoindex on;
        alias /var/log/nginx/;
    }

    # Point de contrôle pour HAProxy
    location /health {
        return 200 "OK\n";
    }
}
EOF

# Configuration des règles Snort de base
echo "🔧 Configuration des règles Snort..."
cat > snort/rules/local.rules << 'EOF'
# Règles Snort de base pour le laboratoire

# SQL Injection
alert tcp any any -> any 80 (msg:"SQL Injection Attempt"; content:"SELECT"; nocase; content:"FROM"; nocase; distance:1; pcre:"/SELECT.+FROM/i"; sid:1000001; rev:1;)

# XSS
alert tcp any any -> any 80 (msg:"XSS Attempt"; content:"<script>"; nocase; sid:1000002; rev:1;)

# Command Injection
alert tcp any any -> any 80 (msg:"Command Injection Attempt"; content:"|3b|"; content:"|7c|"; pcre:"/;|\||`/"; sid:1000003; rev:1;)

# File Inclusion
alert tcp any any -> any 80 (msg:"File Inclusion Attempt"; content:"=../"; sid:1000004; rev:1;)
EOF

# Configuration de Filebeat
echo "🔧 Configuration de Filebeat..."
cat > filebeat/filebeat.yml << 'EOF'
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/snort/*.log*

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
EOF

# Création des scripts de démarrage pour les scénarios
echo "🔧 Création des scripts de démarrage..."

# Script pour démarrer le module core
cat > start-core.sh << 'EOF'
#!/bin/bash
echo "🚀 Démarrage du module core..."
docker-compose up -d
echo "✅ Module core démarré. Accès principal: http://localhost:6080 (root/kali)"
EOF
chmod +x start-core.sh

# Script pour le scénario web
cat > start-web-scenario.sh << 'EOF'
#!/bin/bash
echo "🚀 Démarrage du scénario de sécurité web..."
docker-compose up -d
docker-compose -f docker-compose.web.yml up -d
echo "✅ Scénario web démarré!"
echo "🔗 Accès principaux:"
echo "  - Kali Linux: http://localhost:6080 (root/kali)"
echo "  - DVWA: http://localhost:8080 (admin/password)"
echo "  - Application bancaire: http://localhost:8082"
echo "  - Serveur web vulnérable: http://localhost:8083"
EOF
chmod +x start-web-scenario.sh

# Script pour le scénario IoT
cat > start-iot-scenario.sh << 'EOF'
#!/bin/bash
echo "🚀 Démarrage du scénario de sécurité IoT..."
docker-compose up -d
docker-compose -f docker-compose.iot.yml up -d
echo "✅ Scénario IoT démarré!"
echo "🔗 Accès principaux:"
echo "  - Kali Linux: http://localhost:6080 (root/kali)"
echo "  - Thermostat IoT: http://localhost:8086"
echo "  - Caméra IoT: http://localhost:8087"
echo "  - MQTT Broker: localhost:1883"
EOF
chmod +x start-iot-scenario.sh

# Script pour le scénario d'équilibrage de charge
cat > start-lb-scenario.sh << 'EOF'
#!/bin/bash
echo "🚀 Démarrage du scénario d'équilibrage de charge..."
docker-compose up -d
docker-compose -f docker-compose.lb.yml up -d
echo "✅ Scénario d'équilibrage de charge démarré!"
echo "🔗 Accès principaux:"
echo "  - Kali Linux: http://localhost:6080 (root/kali)"
echo "  - HAProxy Statistics: http://localhost:8404/stats"
echo "  - Application équilibrée: http://localhost"
EOF
chmod +x start-lb-scenario.sh

# Script pour le scénario de monitoring
cat > start-monitoring-scenario.sh << 'EOF'
#!/bin/bash
echo "🚀 Démarrage du scénario de monitoring et détection..."
docker-compose up -d
docker-compose -f docker-compose.monitoring.yml up -d
echo "✅ Scénario de monitoring démarré!"
echo "🔗 Accès principaux:"
echo "  - Kali Linux: http://localhost:6080 (root/kali)"
echo "  - Kibana: http://localhost:5601"
echo "  - Elasticsearch: http://localhost:9200"
EOF
chmod +x start-monitoring-scenario.sh

# Script pour démarrer tous les modules
cat > start-all.sh << 'EOF'
#!/bin/bash
echo "🚀 Démarrage de tous les modules du laboratoire..."
docker-compose up -d
docker-compose -f docker-compose.web.yml up -d
docker-compose -f docker-compose.iot.yml up -d
docker-compose -f docker-compose.lb.yml up -d
docker-compose -f docker-compose.monitoring.yml up -d
echo "✅ Tous les modules démarrés! Attention à la consommation des ressources."
echo "🔗 Accès principaux:"
echo "  - Kali Linux: http://localhost:6080 (root/kali)"
echo "  - DVWA: http://localhost:8080 (admin/password)"
echo "  - HAProxy: http://localhost:8404/stats"
echo "  - Kibana: http://localhost:5601"
EOF
chmod +x start-all.sh

# Script pour arrêter tous les services
cat > stop-all.sh << 'EOF'
#!/bin/bash
echo "🛑 Arrêt de tous les modules du laboratoire..."
docker-compose -f docker-compose.monitoring.yml down
docker-compose -f docker-compose.lb.yml down
docker-compose -f docker-compose.iot.yml down
docker-compose -f docker-compose.web.yml down
docker-compose down
echo "✅ Tous les modules arrêtés."
EOF
chmod +x stop-all.sh

echo "✅ Configuration terminée avec succès!"
echo ""
echo "📋 Prochaines étapes:"
echo "  1. Démarrez le module core: ./start-core.sh"
echo "  2. Ou démarrez un scénario spécifique:"
echo "     - Sécurité Web: ./start-web-scenario.sh"
echo "     - Sécurité IoT: ./start-iot-scenario.sh"
echo "     - Équilibrage de charge: ./start-lb-scenario.sh"
echo "     - Monitoring: ./start-monitoring-scenario.sh"
echo ""
echo "⚠️ Ce laboratoire contient des systèmes délibérément vulnérables."
echo "   Il est destiné uniquement à des fins éducatives."
echo "   Ne pas déployer sur un réseau de production!"
