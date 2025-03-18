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
