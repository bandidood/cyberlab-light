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
