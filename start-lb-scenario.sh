#!/bin/bash
echo "🚀 Démarrage du scénario d'équilibrage de charge..."
docker-compose up -d
docker-compose -f docker-compose.lb.yml up -d
echo "✅ Scénario d'équilibrage de charge démarré!"
echo "🔗 Accès principaux:"
echo "  - Kali Linux: http://localhost:6080 (root/kali)"
echo "  - HAProxy Statistics: http://localhost:8404/stats"
echo "  - Application équilibrée: http://localhost"
