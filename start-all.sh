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
