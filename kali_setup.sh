#!/bin/bash
set -e

echo "Installation des paquets..."
apt update
apt install -y xfce4 xfce4-terminal x11vnc xvfb novnc net-tools curl openssh-server dbus-x11

echo "Configuration du serveur X virtuel..."
Xvfb :1 -screen 0 1280x800x16 &
sleep 2

echo "Démarrage de l'environnement de bureau..."
DISPLAY=:1 startxfce4 &
sleep 5

echo "Configuration de VNC..."
mkdir -p /root/.vnc
x11vnc -storepasswd kalipass /root/.vnc/passwd
x11vnc -display :1 -rfbport 5901 -usepw -forever -create -bg

echo "Démarrage de noVNC..."
/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080 &

echo "Configuration terminée, serveur prêt."
# Maintenir le conteneur en exécution
tail -f /dev/null