# CyberLab Light - Laboratoire de Cybersécurité Modulaire


CyberLab Light est un environnement de laboratoire de cybersécurité léger, modulaire et basé sur Docker. Conçu pour fonctionner avec des ressources limitées, il permet de déployer des scénarios spécifiques à la demande.

## ✨ Caractéristiques

- **Modulaire** - Déployez uniquement les composants nécessaires à votre scénario
- **Léger** - Optimisé pour fonctionner sur des machines avec ressources limitées
- **Docker-based** - Isolation complète et déploiement simplifié
- **Extensible** - Ajoutez facilement de nouveaux modules selon vos besoins

## 🚀 Modules disponibles

CyberLab Light est divisé en modules spécialisés que vous pouvez déployer séparément ou ensemble :

### 🧰 Module Core (Base)
Composants essentiels pour tous les scénarios :
- Kali Linux avec outils de pentest
- Réseau d'administration
- Routeur central

### 🌐 Module Web
Environnement de sécurité web :
- DVWA (Damn Vulnerable Web Application)
- Application bancaire vulnérable
- DMZ isolée

### 📡 Module IoT
Laboratoire de sécurité IoT :
- Broker MQTT
- Dispositifs IoT vulnérables (thermostat, caméra)
- Passerelle IoT

### ⚖️ Module Load Balancing
Infrastructure d'équilibrage de charge :
- HAProxy comme équilibreur principal
- Backends Nginx vulnérables
- Application API vulnérable

### 🔍 Module Monitoring
Surveillance et détection d'intrusions :
- Système de détection d'intrusions Snort
- Elasticsearch pour l'analyse de logs
- Visualisation avec Kibana

## 🚀 Démarrage rapide

### Prérequis
- Docker Engine 20.10+
- Docker Compose 2.0+
- 4 Go RAM minimum (8 Go recommandés pour plusieurs modules)
- 20 Go d'espace disque

### Installation de base

```bash
# Cloner le dépôt
git clone https://github.com/votre-username/cyberlab-light.git
cd cyberlab-light

# Configuration initiale
./setup.sh

# Démarrer uniquement le module core
./start-core.sh
```

### Démarrer un scénario spécifique

```bash
# Scénario complet de sécurité web
./start-web-scenario.sh

# Scénario d'analyse de vulnérabilités IoT
./start-iot-scenario.sh

# Scénario d'attaque contre équilibreur de charge
./start-lb-scenario.sh

# Scénario de détection d'intrusion
./start-monitoring-scenario.sh
```

## 📋 Structure des réseaux

Le laboratoire utilise quatre réseaux isolés :

| Réseau | Plage IP | Description |
|--------|----------|-------------|
| Management | 10.10.10.0/24 | Réseau d'administration et surveillance |
| Corporate LAN | 192.168.1.0/24 | Réseau interne d'entreprise |
| DMZ | 172.16.1.0/24 | Zone démilitarisée pour services exposés |
| IoT | 192.168.2.0/24 | Réseau d'appareils IoT |

## 🔑 Accès principaux

| Service | URL | Identifiants |
|---------|-----|--------------|
| Kali Linux | http://localhost:6080 | root / kali |
| DVWA | http://localhost:8080 | admin / password |
| Application Bancaire | http://localhost:8082 | user / password123 |
| HAProxy Stats | http://localhost:8404/stats | N/A |
| Kibana | http://localhost:5601 | elastic / changeme |

Pour plus de détails, consultez [docs/ACCESS.md](docs/ACCESS.md).

## 🎯 Scénarios disponibles

Le laboratoire inclut plusieurs scénarios pré-configurés :

1. **Attaques Web** - Exploitation de vulnérabilités OWASP Top 10
2. **Sécurité IoT** - Attaques contre protocoles et appareils IoT
3. **Load Balancing** - Vulnérabilités d'infrastructure d'équilibrage
4. **Détection d'intrusion** - Configuration et test d'IDS

Pour les instructions détaillées, voir [docs/SCENARIOS.md](docs/SCENARIOS.md).

## 📊 Gestion des ressources

CyberLab Light est conçu pour minimiser l'utilisation des ressources :

- **Utilisation sélective** - Démarrez uniquement les composants nécessaires
- **Images légères** - Versions Alpine quand c'est possible
- **Limitation de ressources** - Contraintes mémoire et CPU configurables
- **Démarrage à la demande** - Démarrez/arrêtez les services selon les besoins

## 🔧 Personnalisation

Pour adapter le laboratoire à vos besoins :

1. Modifiez les fichiers docker-compose spécifiques
2. Ajustez les limites de ressources dans les scripts de démarrage
3. Ajoutez des services supplémentaires dans le module approprié
4. Créez vos propres scénarios en combinant différents modules

## ⚠️ Avertissement de sécurité

Ce laboratoire contient des systèmes intentionnellement vulnérables. Pour un usage sécurisé :

- Utilisez dans un environnement isolé et contrôlé
- Ne l'exposez jamais à Internet
- Utilisez-le uniquement à des fins éducatives
- Arrêtez les conteneurs quand vous ne les utilisez pas

## 📚 Documentation

- [Guide d'installation](docs/INSTALL.md)
- [Informations d'accès](docs/ACCESS.md)
- [Scénarios détaillés](docs/SCENARIOS.md)
- [Architecture technique](docs/ARCHITECTURE.md)

## 🤝 Contribution

Les contributions sont les bienvenues ! Consultez [CONTRIBUTING.md](CONTRIBUTING.md) pour les directives.

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

⭐ Si vous trouvez ce projet utile, n'hésitez pas à lui donner une étoile sur GitHub !
