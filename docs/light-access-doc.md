# Informations d'accès - CyberLab Light

Ce document contient toutes les informations d'accès aux différents services et systèmes du laboratoire CyberLab Light, organisées par module.

## Module Core

| Service | URL | Identifiants | Description |
|---------|-----|--------------|-------------|
| **Kali Linux (GUI)** | http://localhost:6080 | root / kali | Interface NoVNC |
| **Kali Linux (SSH)** | localhost:2222 | root / kali | `ssh root@localhost -p 2222` |
| **Client Windows** | http://192.168.1.10 | N/A | Simulation d'un client Windows |

## Module Web

| Service | URL | Identifiants | Description |
|---------|-----|--------------|-------------|
| **DVWA** | http://localhost:8080 | admin / password | Damn Vulnerable Web Application |
| **Application Bancaire** | http://localhost:8082 | admin / password<br>ou<br>user / password123 | Application vulnérable aux injections SQL |
| **Serveur Web Vulnérable** | http://localhost:8083 | N/A | Serveur avec multiples vulnérabilités |
| **Reverse Proxy** | http://localhost:8084 | N/A | Proxy inversé |
| **Traefik Dashboard** | http://localhost:8085 | N/A | Interface d'admin de Traefik |

### Exploitation des vulnérabilités Web

Pour l'application bancaire, essayez:
- Nom d'utilisateur: `admin' --`
- Mot de passe: `anything`

## Module IoT

| Service | URL/Port | Identifiants | Description |
|---------|----------|--------------|-------------|
| **MQTT Broker** | localhost:1883 | N/A | Protocole MQTT non sécurisé |
| **MQTT WebSockets** | localhost:9001 | N/A | Accès MQTT via WebSockets |
| **Thermostat IoT** | http://localhost:8086 | N/A | API REST non sécurisée |
| **Caméra IoT** | http://localhost:8087 | N/A | Simulation de caméra IoT |

### Exploitation des vulnérabilités IoT

Pour le thermostat IoT:
```
# Obtenir la température actuelle
curl http://localhost:8086/api/temperature

# Modifier la température cible (sans authentification)
curl -X POST http://localhost:8086/api/target -H "Content-Type: application/json" -d '{"temperature": 30.0}'
```

Pour le MQTT:
```
# S'abonner à tous les topics
mosquitto_sub -h localhost -p 1883 -t "#"

# Publier un message
mosquitto_pub -h localhost -p 1883 -t "home/thermostat/command" -m '{"action":"set", "temperature":25}'
```

## Module Load Balancing

| Service | URL | Identifiants | Description |
|---------|-----|--------------|-------------|
| **HAProxy Statistics** | http://localhost:8404/stats | N/A | Interface d'administration non sécurisée |
| **Application équilibrée** | http://localhost | N/A | Frontend web principal |
| **API Backend** | http://localhost/api/user | N/A | Service API vulnérable |

### Exploitation des vulnérabilités Load Balancing

Pour l'API vulnérable:
```
# Injection de commande via l'API
curl -X POST http://localhost/api/ping -H "Content-Type: application/json" -d '{"host":"localhost; cat /etc/passwd"}'
```

Pour tester l'équilibrage:
```
# Connexions répétées pour voir l'équilibrage round-robin
for i in {1..10}; do curl -s http://localhost/ | grep "Backend"; done
```

## Module Monitoring

| Service | URL | Identifiants | Description |
|---------|-----|--------------|-------------|
| **Elasticsearch** | http://localhost:9200 | N/A | Moteur de recherche et d'analyse |
| **Kibana** | http://localhost:5601 | N/A | Interface de visualisation |

### Utilisation des outils de monitoring

Création d'une règle Snort personnalisée:
1. Ajouter votre règle dans `./snort/rules/local.rules`
2. Redémarrer le conteneur Snort: `docker restart snort`

Visualisation des logs:
1. Accéder à Kibana: http://localhost:5601
2. Configurer un index pattern: `filebeat-*`
3. Accéder à "Discover" pour voir les logs

## Cartographie des réseaux

| Réseau | Plage d'adresses | Composants |
|--------|------------------|------------|
| **Management** | 10.10.10.0/24 | Kali Linux, Monitoring |
| **Corporate** | 192.168.1.0/24 | Client Windows, Passerelle IoT |
| **DMZ** | 172.16.1.0/24 | Applications Web, Load Balancers |
| **IoT** | 192.168.2.0/24 | MQTT, Thermostat, Caméra |

## Accès aux services depuis Kali Linux

À l'intérieur du conteneur Kali Linux, vous pouvez accéder à tous les services directement via leurs adresses IP internes:

```bash
# Accéder à Kali Linux
docker exec -it kali_linux bash

# Scanner un réseau (ex: DMZ)
nmap -sV 172.16.1.0/24

# Accéder à l'application bancaire
curl http://172.16.1.11/

# Tester le MQTT
apt update && apt install -y mosquitto-clients
mosquitto_sub -h 192.168.2.2 -t "#"
```

## Accès aux conteneurs en ligne de commande

Pour accéder directement aux conteneurs:

```bash
# Kali Linux
docker exec -it kali_linux bash

# Routeur
docker exec -it router bash

# DVWA
docker exec -it dvwa bash

# HAProxy
docker exec -it haproxy sh

# Conteneur IoT
docker exec -it iot_thermostat sh
```

## Résolution de problèmes d'accès

Si vous ne pouvez pas accéder à un service:

1. Vérifiez que le conteneur est en cours d'exécution:
   ```bash
   docker ps | grep nom_du_service
   ```

2. Vérifiez les logs du conteneur:
   ```bash
   docker logs nom_du_service
   ```

3. Vérifiez que le port est correctement exposé:
   ```bash
   docker port nom_du_service
   ```

4. Vérifiez la connexion réseau interne:
   ```bash
   docker exec -it kali_linux ping adresse_ip_du_service
   ```

## Notes importantes

- Les mots de passe utilisés sont volontairement simples pour faciliter l'apprentissage
- Certains services n'ont pas d'authentification par conception (pour illustrer les vulnérabilités)
- Tous les services fonctionnent dans un environnement isolé Docker et ne sont pas exposés à Internet
