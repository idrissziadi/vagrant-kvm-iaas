#!/bin/bash
# =====================================================
# Script : installClient.sh
# Objectif : Installer un client KVM (virt-manager)
#             pour se connecter à un serveur distant via SSH
# Système : CentOS Stream 10
# Auteur : Idriss Ziadi (adapté)
# =====================================================
  
set -e
echo "=== Installation du client KVM sur CentOS Stream 10 ==="

# Mise à jour
sudo dnf -y update

# Dépôts CRB et EPEL
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --set-enabled crb || true
sudo dnf install -y epel-release

# Installer virt-manager et outils client
sudo dnf install -y virt-manager virt-viewer libvirt-client openssh-clients qemu-kvm

# Ajouter l'utilisateur courant au groupe libvirt
USER_NAME=$(whoami)
sudo usermod -aG libvirt $USER_NAME || true

echo "Client KVM prêt à se connecter au serveur !"
