#!/bin/bash
# =====================================================
# Script : install_kvm_server.sh
# Objectif : Installer et configurer un serveur KVM sur CentOS Stream 9/10
# Auteur : Idriss Ziadi
# =====================================================



set -e
    

PHYS_IF="eth1"

echo "=== Installation du serveur KVM sur CentOS Stream ==="

# 1. Mise à jour du système
echo "[1/6] Mise à jour du système..."
sudo dnf -y update

# 2. Activation des dépôts nécessaires (CRB et EPEL)
echo "[2/6] Activation des dépôts CRB et EPEL..."
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --set-enabled crb || echo "Dépôt CRB déjà activé"
sudo dnf install -y epel-release
sudo dnf update -y

# 3. Installer KVM et outils associés
echo "[3/6] Installation des paquets KVM..."
sudo dnf install -y qemu-kvm libvirt virt-install virt-manager bridge-utils \
libvirt-daemon libvirt-daemon-driver-qemu libvirt-client

# 4. Activer et démarrer le service libvirtd
echo "[4/6] Activation et démarrage du service libvirtd..."
sudo systemctl enable --now libvirtd

# 5. Ajouter l'utilisateur courant au groupe libvirt
USER_NAME=$(whoami)
echo "[5/6] Ajout de l'utilisateur $USER_NAME au groupe libvirt..."
sudo usermod -aG libvirt $USER_NAME || true
echo "Déconnexion/reconnexion nécessaire pour prise en compte du groupe."

# 6. Créer le bridge réseau KVM dynamiquement
BRIDGE="kvmbr0"
BRIDGE_IP="10.10.0.1/24"



# Créer le bridge seulement s'il n'existe pas
nmcli connection show | grep -q "^$BRIDGE" || \
    sudo nmcli connection add type bridge con-name $BRIDGE ifname $BRIDGE

# Ajouter l’interface physique au bridge seulement si elle n’est pas déjà attachée
nmcli connection show | grep -q "$PHYS_IF.*$BRIDGE" || \
    sudo nmcli connection add type bridge-slave con-name $PHYS_IF ifname $PHYS_IF master $BRIDGE

# Redémarrer NetworkManager pour appliquer les changements
sudo systemctl restart NetworkManager

# Configurer IP statique sur le bridge
sudo nmcli connection modify $BRIDGE ipv4.addresses $BRIDGE_IP
sudo nmcli connection modify $BRIDGE ipv4.method manual
sudo nmcli connection up $BRIDGE

echo "✅ Serveur KVM installé et le bridge $BRIDGE configuré avec IP $BRIDGE_IP !"
