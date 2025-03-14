# Guide d'installation de CyberLab Light

Ce guide vous accompagne à travers l'installation et la configuration de CyberLab Light sur différentes plateformes.

## Prérequis système

### Configuration minimale recommandée
- **CPU**: 2 cœurs (4+ recommandés)
- **RAM**: 4 Go minimum (8 Go recommandés)
- **Stockage**: 20 Go d'espace libre
- **Connexion Internet**: Pour télécharger les images Docker

### Systèmes d'exploitation supportés
- **Linux**: Ubuntu 20.04+, Debian 10+, Fedora 33+
- **macOS**: Catalina (10.15) ou plus récent
- **Windows**: Windows 10/11 avec WSL2

## Installation des prérequis

### Sous Linux (Ubuntu/Debian)

```bash
# Mettre à jour le système
sudo apt update && sudo apt upgrade -y

# Installer Docker
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Installer Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Ajouter votre utilisateur au groupe docker (pour éviter d'utiliser sudo)
sudo usermod -aG docker $USER
newgrp docker
```

### Sous macOS

1. Télécharger et installer [Docker Desktop pour Mac](https://docs.docker.com/desktop/install/mac-install/)
2. Vérifier l'installation:
   ```bash
   docker --version
   docker-compose --version
   ```

### Sous Windows avec WSL2

1. Installer WSL2 (Windows Subsystem for Linux 2):
   ```powershell
   # Dans PowerShell en tant qu'administrateur
   wsl --install
   ```

2. Installer [Docker Desktop pour Windows](https://docs.docker.com/desktop/install/windows-install/) avec l'intégration WSL2

3. Configurer Docker Desktop:
   - Activer l'intégration avec votre distribution WSL2
   - Allouer suffisamment de ressources (CPU/RAM) dans les paramètres

## Installation de CyberLab Light

### Étape 1: Cloner le dépôt

```bash
# Cloner le dépôt
git clone https://github.com/votre-username/cyberlab-light.git
cd cyberlab-light
```

### Étape 2: Exécuter le script de configuration

```bash
# Rendre le script exécutable
chmod +x setup.sh

# Exécuter le script de configuration
./setup.sh
```

Ce script va:
- Créer la structure de répertoires nécessaire
- Générer les fichiers de configuration
- Préparer les applications vulnérables
- Créer les scripts de démarrage des scénarios

### Étape 3: Vérifier l'installation

Assurez-vous que la structure de fichiers suivante a été créée:

```
cyberlab-light/
├── docker-compose.yml            # Module Core
├── docker-compose.web.yml        # Module Web
├── docker-compose.iot.yml        # Module IoT
├── docker-compose.lb.yml         # Module Load Balancing
├── docker-compose.monitoring.yml # Module Monitoring
├── start-core.sh                 # Script de démarrage Core
├── start-web-scenario.sh         # Script pour scénario Web
├── start-iot-scenario.sh         # Script pour scénario IoT
├── start-lb-scenario.sh          # Script pour scénario Load Balancing
├── start-monitoring-scenario.sh  # Script pour scénario Monitoring
├── start-all.sh                  # Script pour tout démarrer
├── stop-all.sh                   # Script pour tout arrêter
└── [différents répertoires de configuration]
```

## Utilisation de base

### Démarrer un scénario spécifique

Chaque scénario a son propre script de démarrage qui lance uniquement les composants nécessaires:

```bash
# Pour le module de base (Kali Linux + routeur)
./start-core.sh

# Pour le scénario de sécurité Web
./start-web-scenario.sh

# Pour le scénario IoT
./start-iot-scenario.sh

# Pour le scénario d'équilibrage de charge
./start-lb-scenario.sh

# Pour le scénario de monitoring et détection
./start-monitoring-scenario.sh
```

### Arrêter tous les services

```bash
./stop-all.sh
```

## Personnalisation

### Modifier les limites de ressources

Les limites de ressources sont définies dans chaque fichier docker-compose. Vous pouvez les ajuster selon votre configuration:

```yaml
# Exemple dans docker-compose.yml
services:
  kali_linux:
    deploy:
      resources:
        limits:
          cpus: '1'    # Augmenter si nécessaire
          memory: 1G   # Augmenter si nécessaire
```

### Ajouter des services personnalisés

1. Créez un nouveau fichier docker-compose (par exemple `docker-compose.custom.yml`)
2. Définissez vos services en vous assurant qu'ils utilisent les réseaux existants comme "external"
3. Créez un script de démarrage correspondant:

```bash
#!/bin/bash
echo "🚀 Démarrage du scénario personnalisé..."
docker-compose up -d
docker-compose -f docker-compose.custom.yml up -d
echo "✅ Scénario personnalisé démarré!"
```

## Résolution des problèmes courants

### Problèmes de ports déjà utilisés

Si certains ports sont déjà utilisés sur votre système:

```bash
# Trouver le processus utilisant un port spécifique (ex: 8080)
sudo lsof -i :8080

# Modifier les mappings de ports dans le fichier docker-compose correspondant
# Par exemple, changer "8080:80" en "8081:80"
```

### Problèmes de mémoire insuffisante

Si Docker indique qu'il n'y a pas assez de mémoire:

1. Démarrez un scénario plus léger ou un seul module
2. Réduisez les limites de mémoire dans les fichiers docker-compose
3. Augmentez la mémoire allouée à Docker (dans Docker Desktop sur Windows/Mac)

### Problèmes de permissions

Sur Linux, si vous avez des problèmes de permissions:

```bash
# Résoudre les problèmes de permissions pour les répertoires créés
sudo chown -R $USER:$USER .
```

## Installation sur un serveur distant

Pour installer le laboratoire sur un serveur accessible via le réseau:

1. Installez Docker et Docker Compose sur le serveur
2. Suivez les étapes d'installation normales
3. Exposez uniquement les ports nécessaires dans votre pare-feu
4. Utilisez un VPN ou SSH tunneling pour un accès sécurisé

## Mode économie d'énergie

Pour réduire davantage la consommation de ressources:

```bash
# Désactiver les services les plus lourds quand ils ne sont pas utilisés
docker-compose stop elasticsearch kibana
```

---

Pour toute question ou problème d'installation, n'hésitez pas à ouvrir une issue sur GitHub ou à contacter l'équipe de maintenance du projet.
