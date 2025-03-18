#!/bin/bash
echo "🚀 Démarrage du scénario de monitoring et détection..."
docker-compose up -d
docker-compose -f docker-compose.monitoring.yml up -d
echo "✅ Scénario de monitoring démarré!"
echo "🔗 Accès principaux:"
echo "  - Kali Linux: http://localhost:6080 (root/kali)"
echo "  - Kibana: http://localhost:5601"
echo "  - Elasticsearch: http://localhost:9200"
