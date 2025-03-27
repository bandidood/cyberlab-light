# Architecture technique - CyberLab Light

Ce document détaille l'architecture technique du laboratoire CyberLab Light, sa structure modulaire, les technologies utilisées et les interactions entre les différents composants.

## Vue d'ensemble

CyberLab Light adopte une architecture modulaire basée sur Docker, divisée en cinq modules spécialisés qui peuvent fonctionner indépendamment ou ensemble. Cette approche permet une utilisation efficace des ressources et une flexibilité maximale.

```
┌─────────────────────────────────────────────────────────────────┐
│                         Module Core                             │
│  ┌──────────┐  ┌────────┐  ┌────────────────┐  ┌────────────┐  │
│  │ Kali Linux│  │ Routeur│  │ Client Windows │  │ Réseaux    │  │
│  └──────────┘  └────────┘  └────────────────┘  └────────────┘  │
└─────────────────────────────────────────────────────────────────┘
             ▲           ▲             ▲              ▲
             │           │             │              │
             ▼           ▼             ▼              ▼
┌────────────┐  ┌───────────────┐  ┌──────────┐  ┌───────────────┐
│ Module Web │  │ Module IoT    │  │ Module LB│  │ Module        │
│            │  │               │  │          │  │ Monitoring    │
└────────────┘  └───────────────┘  └──────────┘  └───────────────┘
```

## Structure des réseaux

Le laboratoire utilise quatre réseaux Docker isolés pour simuler différents segments d'une infrastructure réelle:

1. **Management Network (10.99.10.0/24)**
   - Réseau d'administration et de surveillance
   - Héberge l'accès principal à Kali Linux
   - Contient les services de monitoring comme Elasticsearch et Kibana

2. **Corporate LAN (192.168.99.0/24)**
   - Simule un réseau d'entreprise interne
   - Contient le client Windows simulé
   - Point de connexion avec les autres réseaux via le routeur

3. **DMZ Network (172.16.99.0/24)**
   - Zone démilitarisée pour les services exposés
   - Héberge les applications web vulnérables
   - Contient l'infrastructure d'équilibrage de charge

4. **IoT Network (192.168.98.0/24)**
   - Réseau isolé pour les appareils IoT
   - Contient le broker MQTT, thermostat et caméra
   - Connecté au réseau corporate via la passerelle IoT

## Architecture modulaire

### Module Core (Base)

Le module Core fournit les composants essentiels nécessaires à tous les scénarios:

- **Kali Linux**: Distribution de cybersécurité avec interface graphique via NoVNC
  - Image: `kalilinux/kali-rolling`
  - Outils essentiels: nmap, metasploit, burpsuite, wireshark
  - Adresse IP: 10.99.10.10 (management), 192.168.99.10 (corporate)
  - Limitations de ressources: 1 CPU, 1 Go RAM

- **Routeur**: Gère l'interconnexion entre les différents réseaux
  - Image: `frrouting/frr` (routeur léger)
  - Configuration: Transfert IP activé
  - Adresses IP:
    - 10.99.10.1 (management)
    - 192.168.99.1 (corporate)
    - 172.16.99.1 (dmz)
    - 192.168.98.1 (iot)

- **Client Windows** (simulé): Cible potentielle dans le réseau corporate
  - Image: `alpine` (simulation légère)
  - Serveur HTTP simple pour tester la connectivité
  - Adresse IP: 192.168.99.20

### Module Web

Consacré aux vulnérabilités web et applications vulnérables:

- **DVWA**: Application web volontairement vulnérable
  - Image: `vulnerables/web-dvwa`
  - Adresse IP: 172.16.99.10
  - Vulnérabilités: SQL injection, XSS, CSRF, upload, etc.

- **Application Bancaire**: Application PHP vulnérable simplifiée
  - Image: `php:7.4-apache`
  - Adresse IP: 172.16.99.11
  - Vulnérabilités: Injection SQL, authentification faible

- **Serveur Web Vulnérable**: Serveur statique avec vulnérabilités de configuration
  - Image: `nginx:alpine`
  - Adresse IP: 172.16.99.12
  - Vulnérabilités: traversée de répertoire, upload non sécurisé

- **Reverse Proxy**: Proxy pour la redirection de trafic
  - Image: `traefik:latest`
  - Adresses IP: 172.16.99.13 (dmz), 10.99.10.30 (management)
  - Configuration minimale pour économiser les ressources

### Module IoT

Simule un environnement IoT avec des dispositifs vulnérables:

- **MQTT Broker**: Serveur de messagerie pour IoT
  - Image: `eclipse-mosquitto:2.0-openssl`
  - Adresse IP: 192.168.98.2
  - Configuration: authentification anonyme autorisée

- **Thermostat IoT**: Dispositif IoT vulnérable
  - Image: `python:3.9-alpine`
  - Adresse IP: 192.168.98.10
  - Application Flask simulant un thermostat
  - Vulnérabilités: API sans authentification, communications non chiffrées

- **Caméra IoT**: Dispositif d'imagerie simulé
  - Image: `alpine`
  - Adresse IP: 192.168.98.11
  - Serveur web Python léger
  - Vulnérabilités: accès non authentifié

- **Passerelle IoT**: Connecte le réseau IoT au réseau corporate
  - Image: `python:3.9-alpine`
  - Adresses IP: 192.168.98.50 (IoT), 192.168.99.50 (corporate)
  - Vulnérabilités: injection de commande dans l'API ping

### Module Load Balancing

Simule une infrastructure d'équilibrage de charge avec vulnérabilités:

- **HAProxy**: Équilibreur de charge principal
  - Image: `haproxy:alpine` (version légère)
  - Adresses IP: 172.16.99.20 (dmz), 10.99.10.20 (management)
  - Configuration: sticky sessions, interface stats non sécurisée

- **Backend 1 & 2**: Serveurs web derrière l'équilibreur
  - Image: `nginx:alpine`
  - Adresses IP: 172.16.99.21 (backend1), 172.16.99.22 (backend2)
  - Vulnérabilités différentes sur chaque backend:
    - Backend 1: traversée de répertoire
    - Backend 2: CORS trop permissif, exposition de logs

- **API Backend**: Service API vulnérable
  - Image: `python:3.9-alpine`
  - Adresse IP: 172.16.99.23
  - Flask API avec injection de commande

### Module Monitoring

Fournit des capacités de surveillance et de détection d'intrusion:

- **Snort IDS**: Système de détection d'intrusion
  - Image: `linton/docker-snort`
  - Adresses IP: 10.99.10.30 (management), 192.168.99.30 (corporate)
  - Règles personnalisées pour détecter diverses attaques

- **Elasticsearch**: Moteur de stockage et de recherche de logs
  - Image: `docker.elastic.co/elasticsearch/elasticsearch:7.17.0`
  - Adresse IP: 10.99.10.31
  - Configuration optimisée: heap JVM limité à 512Mo

- **Kibana**: Interface de visualisation pour Elasticsearch
  - Image: `docker.elastic.co/kibana/kibana:7.17.0`
  - Adresse IP: 10.99.10.32
  - Visualisation et analyse des données de sécurité

- **Filebeat**: Collecteur de logs pour Snort
  - Image: `docker.elastic.co/beats/filebeat:7.17.0`
  - Adresse IP: 10.99.10.33
  - Configuration pour collecter et transmettre les logs Snort

## Optimisation des ressources

CyberLab Light utilise plusieurs stratégies pour réduire la consommation de ressources:

1. **Images Alpine**: Utilisation de versions Alpine des images quand c'est possible
2. **Limitations explicites**: Contraintes CPU et mémoire définies pour chaque conteneur
3. **Démarrage sélectif**: Modularité permettant de ne démarrer que les composants nécessaires
4. **Simulations légères**: Utilisation de simulations légères plutôt que d'applications complètes quand possible
5. **Services facultatifs**: Certains services lourds peuvent être désactivés si nécessaire

Exemple de limitation de ressources dans les fichiers docker-compose:
```yaml
services:
  kali_linux:
    deploy:
      resources:
        limits:
          cpus: '1'    # Limite à 1 cœur CPU
          memory: 1G   # Limite à 1 Go de RAM
```

## Flux de données

### Flux web typique
1. L'utilisateur accède à Kali Linux via l'interface NoVNC (port 6080)
2. Kali est utilisé pour scanner/attaquer les applications dans la DMZ
3. Les applications web vulnérables répondent avec des vulnérabilités
4. Snort détecte les activités suspectes
5. Les logs sont envoyés à Elasticsearch via Filebeat
6. Les alertes sont visualisées dans Kibana

### Flux IoT typique
1. Le thermostat envoie des données de température au broker MQTT
2. La passerelle IoT s'abonne à ces messages
3. L'utilisateur exploite l'API de la passerelle
4. La passerelle compromise permet le pivotement vers le réseau corporate

### Flux d'équilibrage de charge
1. Les requêtes arrivent sur HAProxy
2. HAProxy distribue aux backends selon l'algorithme configuré
3. L'utilisateur découvre les backends et les attaque directement
4. Les règles Snort détectent certaines attaques

## Extension de l'architecture

L'architecture peut être étendue de plusieurs façons:

1. **Ajout de modules personnalisés**:
   - Créer de nouveaux fichiers docker-compose
   - S'assurer qu'ils utilisent les réseaux existants (external: true)

2. **Scaling des backends**:
   - Ajouter plus de backends dans le module d'équilibrage de charge
   - Mettre à jour la configuration HAProxy

3. **Intégration de services tiers**:
   - Connecter des services cloud simulés
   - Ajouter des environnements mobiles ou blockchain

4. **Persistance des données**:
   - Configurer des volumes pour la persistance entre redémarrages

## Considérations de sécurité

Ce laboratoire contient des systèmes délibérément vulnérables. Pour une utilisation sécurisée:

1. **Isolation réseau**: Le laboratoire est complètement isolé dans des réseaux Docker
2. **Services locaux**: Tous les services ne sont accessibles que depuis localhost
3. **Stockage de mots de passe**: Les mots de passe utilisés sont simples et uniquement à des fins de démonstration
4. **Restart policies**: Configurations pour redémarrer automatiquement en cas de crash

## Schéma d'architecture détaillé

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                             DOCKER HOST                                      │
│                                                                              │
│  ┌────────────────────────┐    ┌────────────────────────┐                    │
│  │    Management Network   │    │    Corporate LAN       │                    │
│  │      10.99.10.0/24     │    │    192.168.99.0/24     │                    │
│  │                        │    │                        │                    │
│  │ ┌──────────────────┐   │    │ ┌──────────────────┐   │                    │
│  │ │   Kali Linux     │   │    │ │  Client Windows  │   │                    │
│  │ │   10.99.10.10    │   │    │ │   192.168.99.20  │   │                    │
│  │ └──────────────────┘   │    │ └──────────────────┘   │                    │
│  │                        │    │                        │                    │
│  │ ┌──────────────────┐   │    │                        │                    │
│  │ │  Elasticsearch   │   │    │                        │                    │
│  │ │   10.99.10.31    │   │    │                        │                    │
│  │ └──────────────────┘   │    │                        │                    │
│  │                        │    │                        │                    │
│  │ ┌──────────────────┐   │    │                        │                    │
│  │ │     Kibana       │   │    │                        │                    │
│  │ │   10.99.10.32    │   │    │                        │                    │
│  │ └──────────────────┘   │    │                        │                    │
│  └────────────────────────┘    └────────────────────────┘                    │
│                                                                              │
│  ┌────────────────────────┐    ┌────────────────────────┐                    │
│  │      DMZ Network       │    │      IoT Network       │                    │
│  │     172.16.99.0/24     │    │     192.168.98.0/24    │                    │
│  │                        │    │                        │                    │
│  │ ┌──────────────────┐   │    │ ┌──────────────────┐   │                    │
│  │ │       DVWA       │   │    │ │   MQTT Broker    │   │                    │
│  │ │    172.16.99.10  │   │    │ │   192.168.98.2   │   │                    │
│  │ └──────────────────┘   │    │ └──────────────────┘   │                    │
│  │                        │    │                        │                    │
│  │ ┌──────────────────┐   │    │ ┌──────────────────┐   │                    │
│  │ │    HAProxy       │   │    │ │    Thermostat    │   │                    │
│  │ │   172.16.99.20   │   │    │ │   192.168.98.10  │   │                    │
│  │ └──────────────────┘   │    │ └──────────────────┘   │                    │
│  │                        │    │                        │                    │
│  │ ┌──────────────────┐   │    │ ┌──────────────────┐   │                    │
│  │ │   Backend 1 & 2  │   │    │ │      Camera      │   │                    │
│  │ │ 172.16.99.21-22  │   │    │ │   192.168.98.11  │   │                    │
│  │ └──────────────────┘   │    │ └──────────────────┘   │                    │
│  └────────────────────────┘    └────────────────────────┘                    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐     │
│  │                            Docker Router                            │     │
│  │             Interconnecte tous les réseaux définis                  │     │
│  └─────────────────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Technologies utilisées

- **Virtualisation**: Docker et Docker Compose
- **Sécurité**: Kali Linux, Snort IDS
- **Web**: DVWA, PHP, Nginx
- **Équilibrage de charge**: HAProxy
- **IoT**: MQTT (Mosquitto), APIs REST
- **Monitoring**: Elasticsearch, Kibana, Filebeat
- **Langues de programmation**: Bash (scripts), Python (IoT et API), PHP (apps web)

## Considérations de performances

Pour optimiser les performances:

1. **Configuration mémoire minimale**: Ajustement des paramètres JVM et autres limites de mémoire
2. **Démarrage stratégique**: Ne démarrer que les services nécessaires au scénario en cours
3. **Options de persistance**: Utilisation de volumes Docker pour les données persistantes
4. **Allocations de ressources**: Ajustement des contraintes de ressources selon les besoins

---

Cette architecture a été conçue pour être légère, modulaire et flexible. Elle peut être adaptée aux besoins spécifiques en activant seulement les modules nécessaires ou en ajustant les limites de ressources.
