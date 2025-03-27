#!/bin/bash
set -e

echo "Installation des paquets..."
export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y xfce4 xfce4-terminal x11vnc xvfb novnc net-tools curl openssh-server dbus-x11 expect

echo "Configuration du serveur X virtuel..."
Xvfb :1 -screen 0 1280x800x16 &
sleep 3

echo "Configuration de VNC..."
mkdir -p /root/.vnc

# Utilisation de expect pour automatiser la création du mot de passe VNC
cat > /tmp/vncsetup.exp << 'EOF'
#!/usr/bin/expect
spawn x11vnc -storepasswd
expect "Enter VNC password:"
send "kali\r"
expect "Verify password:"
send "kali\r"
expect "Write password to"
send "y\r"
expect eof
EOF

chmod +x /tmp/vncsetup.exp
/tmp/vncsetup.exp
rm /tmp/vncsetup.exp

echo "Démarrage de l'environnement de bureau..."
DISPLAY=:1 startxfce4 &
sleep 5

echo "Démarrage de VNC..."
x11vnc -display :1 -rfbport 5901 -rfbauth /root/.vnc/passwd -forever -create -bg

echo "Démarrage de noVNC..."
/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 6080 &

echo "Configuration de SSH..."
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "root:kali" | chpasswd
service ssh start

echo "Configuration terminée, serveur prêt."

# Maintenir le conteneur en exécution
tail -f /dev/null
