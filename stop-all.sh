#!/bin/bash
echo "🛑 Arrêt de tous les modules du laboratoire..."
docker-compose -f docker-compose.monitoring.yml down
docker-compose -f docker-compose.lb.yml down
docker-compose -f docker-compose.iot.yml down
docker-compose -f docker-compose.web.yml down
docker-compose down
echo "✅ Tous les modules arrêtés."
