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
   docker network create --subnet=10.10.10.0/24 management_network
   docker network create --subnet=192.168.1.0/24 corporate_lan
   docker network create --subnet=172.16.1.0/24 dmz_network
   docker network create --subnet=192.168.2.0/24 iot_network
   ```

### Problème: "Les conteneurs ne peuvent pas communiquer entre eux"

**Problème**: Problème de résolution DNS ou de routage entre les conteneurs.

**Solutions**:
1. Vérifiez que tous les conteneurs sont sur les bons réseaux:
   ```bash
   docker network inspect management_network
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

### Problème: "Elasticsearch ne démarre pas"

**Problème**: Elasticsearch nécessite plus de mémoire ou a des problèmes de permissions.

**Solutions**:
1. Vérifiez les logs:
   ```bash
   docker logs elasticsearch
   ```
2. Augmentez temporairement les limites de mémoire:
   ```yaml
   environment:
     - "ES_JAVA_OPTS=-Xms256m -Xmx256m"  # Réduire davantage si nécessaire
   ```
3. Si vous êtes sur Linux, vérifiez le paramètre vm.max_map_count:
   ```bash
   sudo sysctl -w vm.max_map_count=262144
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

## Problèmes courants dans les scénarios

### Problème: "Les exploits ne fonctionnent pas dans DVWA"

**Problème**: DVWA n'est pas configuré correctement.

**Solution**:
1. Assurez-vous que le niveau de sécurité est réglé sur "low":
   - Accédez à http://localhost:8080
   - Allez dans DVWA Security
   - Sélectionnez "low" et cliquez sur "Submit"

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

## Autres problèmes

### Problème: "Impossible d'arrêter les conteneurs"

**Problème**: Les conteneurs refusent de s'arrêter proprement.

**Solution**:
```bash
# Forcer l'arrêt
docker-compose down -v --remove-orphans
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

## Maintenir à jour le laboratoire

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

---

Si vous rencontrez un problème qui n'est pas couvert par ce guide, n'hésitez pas à ouvrir une issue sur GitHub ou à consulter la documentation Docker pour des solutions plus spécifiques.
