# Guide de résolution des problèmes - CyberLab Light

Ce guide aborde les problèmes courants que vous pourriez rencontrer lors de l'utilisation de CyberLab Light et propose des solutions.

## Problèmes de démarrage

### Erreur: "Impossible de trouver l'image 'xxx:latest' localement"

**Problème**: Docker ne peut pas télécharger une image nécessaire.

**Solutions**:
1. Vérifiez votre connexion Internet
2. Assurez-vous que le nom de l'image est correctement orthographié dans le fichier docker-compose
3. Essayez de télécharger manuellement l'image:
   ```bash
   docker pull nom_de_limage:tag
   ```

### Erreur: "port is already allocated"

**Problème**: Le port que Docker tente d'utiliser est déjà occupé par un autre service.

**Solutions**:
1. Identifiez quel service utilise ce port:
   ```bash
   # Sur Linux
   sudo lsof -i :PORT_NUMBER
   
   # Sur Windows
   netstat -ano | findstr :PORT_NUMBER
   ```
2. Modifiez le port dans le fichier docker-compose correspondant:
   ```yaml
   ports:
     - "8081:80"  # Changé de 8080:80
   ```

### Erreur: "Insuffisamment de mémoire pour lancer le laboratoire complet"

**Problème**: Docker n'a pas assez de ressources allouées.

**Solutions**:
1. Démarrez uniquement les modules nécessaires plutôt que tous:
   ```bash
   ./start-web-scenario.sh  # Au lieu de start-all.sh
   ```
2. Réduisez les limites de mémoire dans les fichiers docker-compose:
   ```yaml
   deploy:
     resources:
       limits:
         memory: 512M  # Réduit de 1G à 512M
   ```
3. Fermez les applications gourmandes en mémoire avant de démarrer le laboratoire
4. Sur Docker Desktop (Windows/Mac), augmentez la mémoire allouée à Docker dans les paramètres

## Problèmes de réseau

### Erreur: "network XXX not found"

**Problème**: Le réseau Docker externe n'existe pas encore.

**Solutions**:
1. Assurez-vous de démarrer d'abord le module Core:
   ```bash
   ./start-core.sh
   ```
2. Créez manuellement les réseaux manquants:
   ```bash
   docker network create --subnet=10.99.10.0/24 cyberlab-light_management_network
   docker network create --subnet=192.168.99.0/24 cyberlab-light_corporate_lan
   docker network create --subnet=172.16.99.0/24 cyberlab-light_dmz_network
   docker network create --subnet=192.168.98.0/24 cyberlab-light_iot_network
   ```

### Problème: "Les conteneurs ne peuvent pas communiquer entre eux"

**Problème**: Problème de résolution DNS ou de routage entre les conteneurs.

**Solutions**:
1. Vérifiez que tous les conteneurs sont sur les bons réseaux:
   ```bash
   docker network inspect cyberlab-light_management_network
   ```
2. Testez la connectivité à partir de Kali Linux:
   ```bash
   docker exec -it kali_linux ping router
   ```
3. Vérifiez que le routeur est correctement configuré:
   ```bash
   docker exec -it router ip a
   ```
4. Redémarrez le routeur:
   ```bash
   docker restart router
   ```

## Problèmes avec les services spécifiques

### Problème: "Interface Kali Linux non accessible"

**Problème**: Le service NoVNC ne démarre pas correctement.

**Solutions**:
1. Vérifiez les logs du conteneur:
   ```bash
   docker logs kali_linux
   ```
2. Redémarrez le conteneur:
   ```bash
   docker restart kali_linux
   ```
3. Vérifiez si le service est prêt (attendre quelques minutes après le démarrage):
   ```bash
   docker exec -it kali_linux ps aux | grep novnc
   ```
4. Si le problème persiste, reconstruisez le conteneur:
   ```bash
   docker-compose rm -f kali_linux
   docker-compose up -d kali_linux
   ```

### Kali Linux inaccessible

Le service Kali Linux est particulièrement problématique car il utilise NoVNC pour exposer une interface graphique.

1. **Vérifiez les logs de Kali Linux** :
   ```bash
   docker logs kali_linux
   ```
   Recherchez des erreurs comme "failed to bind to port 6080" ou des problèmes avec X11/VNC.

2. **Vérifiez si les processus NoVNC et VNC sont actifs** :
   ```bash
   docker exec -it kali_linux ps aux | grep -E "vnc|novnc"
   ```

3. **Solution possible** : Redémarrer explicitement les services VNC et NoVNC dans le conteneur :
   ```bash
   docker exec -it kali_linux bash -c "killall x11vnc novnc"
   docker exec -it kali_linux bash -c "Xvfb :1 -screen 0 1280x800x16 &"
   docker exec -it kali_linux bash -c "DISPLAY=:1 startxfce4 &"
   docker exec -it kali_linux bash -c "x11vnc -display :1 -rfbport 5901 -passwd kali -forever -create -bg"
   docker exec -it kali_linux bash -c "/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080 &"
   ```

### Vérification de la configuration réseau

1. **Vérifiez que les réseaux Docker sont correctement créés** :
   ```bash
   docker network ls | grep cyberlab
   ```

2. **Vérifiez les plages d'adresses IP et connexions** :
   ```bash
   docker network inspect cyberlab-light_management_network
   ```

3. **Vérifiez les mappings de ports** :
   ```bash
   docker ps --format "{{.Names}}: {{.Ports}}"
   ```

### Vérification des services individuels

Pour chaque service inaccessible :

1. **Vérifiez que le conteneur est en cours d'exécution** :
   ```bash
   docker ps | grep nom_du_service
   ```

2. **Vérifiez l'état du service à l'intérieur du conteneur** :
   ```bash
   # Pour les services web
   docker exec -it nom_du_service curl localhost:80
   ```

3. **Vérifiez l'accès depuis un autre conteneur** (comme Kali Linux) :
   ```bash
   docker exec -it kali_linux curl http://adresse_ip_du_service:port
   ```

### Problèmes potentiels de pare-feu

Si certains services sont inaccessibles depuis l'hôte mais fonctionnent entre conteneurs :

1. **Vérifiez les pare-feu locaux** (iptables, firewalld, ufw) :
   ```bash
   # Pour UFW
   sudo ufw status
   
   # Pour iptables
   sudo iptables -L
   ```

2. **Désactivez temporairement le pare-feu** (pour test uniquement) :
   ```bash
   sudo ufw disable  # Ubuntu/Debian
   sudo systemctl stop firewalld  # RedHat/CentOS
   ```

### Solution radicale : reconstruire l'environnement

Si les solutions ci-dessus ne fonctionnent pas, vous pouvez essayer une approche radicale :

```bash
# Arrêter tous les conteneurs
./stop-all.sh

# Supprimer tous les conteneurs, réseaux et volumes associés
docker-compose down -v
docker-compose -f docker-compose.web.yml down -v
docker-compose -f docker-compose.iot.yml down -v
docker-compose -f docker-compose.lb.yml down -v
docker-compose -f docker-compose.monitoring.yml down -v

# Nettoyer l'environnement Docker
docker system prune -f

# Redémarrer le service Docker
sudo systemctl restart docker

# Relancer le script de configuration
./setup.sh

# Démarrer les modules nécessaires
./start-core.sh
./start-web-scenario.sh
```

### Problème: "Elasticsearch ne démarre pas"

**Problème**: Elasticsearch nécessite plus de mémoire ou a des problèmes de permissions.

**Solutions**:
1. Vérifiez les logs:
   ```bash
   docker logs elasticsearch
   ```
2. Sur Linux, augmentez la valeur du paramètre vm.max_map_count:
   ```bash
   sudo sysctl -w vm.max_map_count=262144
   ```
3. Si le problème est lié à la mémoire, modifiez les options JVM dans docker-compose.monitoring.yml:
   ```yaml
   environment:
     - "ES_JAVA_OPTS=-Xms256m -Xmx256m"
   ```
4. Vérifiez les permissions du volume:
   ```bash
   sudo chown -R 1000:1000 ./elasticsearch/data
   ```

### Problème: "Les applications web ne fonctionnent pas correctement"

**Problème**: Problèmes de configuration ou d'initialisation des applications web.

**Solutions**:
1. Pour DVWA, vérifiez si la base de données est correctement initialisée:
   ```bash
   docker exec -it dvwa ls -la /var/www/html
   ```
2. Pour les applications PHP personnalisées, vérifiez les permissions:
   ```bash
   docker exec -it vuln_bank_app ls -la /var/www/html
   docker exec -it vuln_bank_app chmod -R 755 /var/www/html
   ```
3. Consultez les logs du serveur web:
   ```bash
   docker logs vuln_bank_app
   ```

### Problème: "MQTT ne fonctionne pas"

**Problème**: Problèmes avec le broker MQTT ou les clients.

**Solutions**:
1. Vérifiez si le service Mosquitto est en cours d'exécution:
   ```bash
   docker exec -it mqtt_broker ps aux | grep mosquitto
   ```
2. Vérifiez la configuration:
   ```bash
   docker exec -it mqtt_broker cat /mosquitto/config/mosquitto.conf
   ```
3. Dans Kali Linux, installez et testez les clients MQTT:
   ```bash
   docker exec -it kali_linux apt-get update && apt-get install -y mosquitto-clients
   docker exec -it kali_linux mosquitto_sub -h mqtt_broker -t "#" -v
   ```
4. Redémarrez le broker:
   ```bash
   docker restart mqtt_broker
   ```

## Problèmes de performances

### Problème: "Le laboratoire est lent"

**Problème**: Ressources insuffisantes ou trop de conteneurs en cours d'exécution.

**Solutions**:
1. Exécutez uniquement les modules dont vous avez besoin:
   ```bash
   ./stop-all.sh
   ./start-web-scenario.sh  # Juste le scénario web
   ```
2. Désactivez les services gourmands en ressources:
   ```bash
   docker stop elasticsearch kibana
   ```
3. Surveillez l'utilisation des ressources:
   ```bash
   docker stats
   ```
4. Sur Docker Desktop, augmentez les ressources allouées à Docker

### Problème: "Espace disque insuffisant"

**Problème**: Docker utilise trop d'espace disque.

**Solutions**:
1. Nettoyez les images, conteneurs et volumes inutilisés:
   ```bash
   docker system prune -a --volumes
   ```
2. Supprimez les images spécifiques que vous n'utilisez pas:
   ```bash
   docker images
   docker rmi image_id_1 image_id_2
   ```
3. Vérifiez l'espace disque utilisé par Docker:
   ```bash
   docker system df
   ```

## Problèmes spécifiques aux scénarios

### Problème: "Les exploits ne fonctionnent pas dans DVWA"

**Problème**: DVWA n'est pas configuré correctement.

**Solution**:
1. Assurez-vous que le niveau de sécurité est réglé sur "low":
   - Accédez à http://localhost:8080
   - Allez dans DVWA Security
   - Sélectionnez "low" et cliquez sur "Submit"
2. Si la base de données n'est pas initialisée, suivez ces étapes:
   - Accédez à http://localhost:8080/setup.php
   - Cliquez sur "Create / Reset Database"

### Problème: "Snort ne détecte pas les attaques"

**Problème**: Règles Snort mal configurées ou trafic non capturé.

**Solutions**:
1. Vérifiez que les règles sont chargées:
   ```bash
   docker exec -it snort cat /etc/snort/rules/local.rules
   ```
2. Assurez-vous que Snort écoute sur les bonnes interfaces:
   ```bash
   docker exec -it snort snort -V
   ```
3. Redémarrez Snort après avoir modifié les règles:
   ```bash
   docker restart snort
   ```
4. Vérifiez que les réseaux sont bien connectés à Snort:
   ```bash
   docker inspect snort | grep -A 10 "Networks"
   ```

### Problème: "Pas de données dans Kibana"

**Problème**: Elasticsearch n'a pas de données ou Filebeat ne fonctionne pas.

**Solutions**:
1. Vérifiez que Filebeat envoie des données:
   ```bash
   docker logs filebeat
   ```
2. Vérifiez qu'Elasticsearch reçoit des données:
   ```bash
   curl http://localhost:9200/_cat/indices
   ```
3. Dans Kibana, créez un index pattern:
   - Accédez à http://localhost:5601
   - Allez dans Management > Stack Management > Index Patterns
   - Créez un pattern "filebeat-*"
4. Vérifiez la connectivité entre Filebeat et Elasticsearch:
   ```bash
   docker exec -it filebeat ping elasticsearch
   ```

## Résolution des problèmes de scripts

### Problème: "Permission denied lors de l'exécution des scripts"

**Problème**: Les scripts n'ont pas les permissions d'exécution.

**Solution**:
```bash
chmod +x *.sh
```

### Problème: "Le script setup.sh a échoué"

**Problème**: Erreur dans le script de configuration.

**Solutions**:
1. Examinez l'erreur affichée
2. Exécutez le script avec un débogage:
   ```bash
   bash -x setup.sh
   ```
3. Essayez d'exécuter manuellement les commandes dans le script
4. Vérifiez les permissions des répertoires:
   ```bash
   ls -la
   ```

## Problèmes de conteneurs spécifiques

### HAProxy

**Problème**: HAProxy ne distribue pas correctement le trafic

**Solutions**:
1. Vérifiez la configuration:
   ```bash
   docker exec -it haproxy cat /usr/local/etc/haproxy/haproxy.cfg
   ```
2. Vérifiez l'état des backend:
   ```bash
   docker exec -it haproxy curl -s http://localhost:8404/stats
   ```
3. Redémarrez HAProxy:
   ```bash
   docker restart haproxy
   ```

### API Backend

**Problème**: L'API backend n'est pas accessible ou renvoie des erreurs

**Solutions**:
1. Vérifiez que le conteneur est en cours d'exécution:
   ```bash
   docker ps | grep api_backend
   ```
2. Vérifiez les logs du conteneur:
   ```bash
   docker logs api_backend
   ```
3. Testez l'API directement:
   ```bash
   curl http://172.16.99.23:5000/
   ```
4. Vérifiez que le fichier app.py est correctement installé:
   ```bash
   docker exec -it api_backend ls -la /app
   ```

## Autres problèmes

### Problème: "Impossible d'arrêter les conteneurs"

**Problème**: Les conteneurs refusent de s'arrêter proprement.

**Solution**:
```bash
# Forcer l'arrêt
docker-compose down -v --remove-orphans

# Si cela ne fonctionne pas
docker rm -f $(docker ps -a -q --filter "name=cyberlab")
```

### Problème: "Perte de données entre les redémarrages"

**Problème**: Les données ne persistent pas entre les redémarrages.

**Solution**:
Ajoutez des volumes nommés dans les fichiers docker-compose:
```yaml
services:
  database:
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```

### Problème: "Ports NoVNC de Kali inaccessibles"

**Problème**: L'interface NoVNC ne répond pas sur le port configuré.

**Solutions**:
1. Vérifiez si les processus VNC et NoVNC fonctionnent:
   ```bash
   docker exec -it kali_linux ps aux | grep -E "vnc|novnc"
   ```
2. Vérifiez les logs pour les erreurs:
   ```bash
   docker logs kali_linux | grep -i error
   ```
3. Redémarrez les services VNC manuellement:
   ```bash
   docker exec -it kali_linux bash -c "x11vnc -display :1 -rfbport 5901 -usepw -forever -create -bg && /usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080"
   ```

## Maintenance et mise à jour

### Maintenir à jour le laboratoire

Pour maintenir le laboratoire à jour:

1. Tirez les dernières modifications du dépôt Git:
   ```bash
   git pull
   ```

2. Reconstruisez les images personnalisées:
   ```bash
   docker-compose build --no-cache
   ```

3. Mettez à jour les images Docker:
   ```bash
   docker-compose pull
   ```

### Sauvegarde et restauration

Pour sauvegarder une configuration fonctionnelle:

1. Sauvegardez les fichiers de configuration:
   ```bash
   tar -czvf cyberlab-config-backup.tar.gz *.yml *.sh */config/* snort/rules/*
   ```

2. Pour restaurer:
   ```bash
   tar -xzvf cyberlab-config-backup.tar.gz
   ```

## Contacter le support

Si vous rencontrez un problème qui n'est pas couvert par ce guide:

1. Consultez les issues existantes sur le dépôt GitHub
2. Ouvrez une nouvelle issue avec:
   - Une description détaillée du problème
   - Les logs pertinents
   - Les étapes pour reproduire le problème
   - Votre environnement (OS, version Docker, etc.)

## Astuces pour un dépannage efficace

1. **Approche systématique**: Commencez par les problèmes les plus simples (connexion réseau, services actifs)
2. **Collecte d'informations**: Rassemblez les logs et les informations système avant de chercher des solutions
3. **Isolation**: Essayez de démarrer les modules un par un pour identifier celui qui pose problème
4. **Reconstruction propre**: En cas de doute, arrêtez tout, nettoyez et recommencez:
   ```bash
   ./stop-all.sh
   docker system prune
   ./setup.sh
   ./start-core.sh
   ```

---

Si vous rencontrez un problème qui n'est pas couvert par ce guide, n'hésitez pas à ouvrir une issue sur GitHub ou à consulter la documentation Docker pour des solutions plus spécifiques.
