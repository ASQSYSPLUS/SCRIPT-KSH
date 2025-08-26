#!/bin/bash

#VERSION BASIQUE----------------------------------------------------------------------
# rclone mount OneDrive-AAZ-ASQSYS: ASQSYS-365-AAZ/ --vfs-cache-mode off --daemon
# rclone mount OneDrive-AZ-A-PERSO: PERSO-AZA/ --vfs-cache-mode off --daemon
# rclone mount OneDrive-CTT-ASQSYS: ASQSYS-365-CONTACT/ --vfs-cache-mode off --daemon

#VERSION AMELIOREE----------------------------------------------------------------------
# Couleurs pour les messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages avec horodatage
log_message() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

# Fonction pour vérifier si un montage est actif
check_mount() {
    local mount_point="$1"
    if mountpoint -q "$mount_point" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Script de montage rclone OneDrive    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Montage 1: OneDrive-AAZ-ASQSYS
log_message "${YELLOW}Étape 1/3: Montage de OneDrive-AAZ-ASQSYS...${NC}"
echo "  Source: OneDrive-AAZ-ASQSYS:"
echo "  Destination: ASQSYS-365-AAZ/"

rclone mount OneDrive-AAZ-ASQSYS: ASQSYS-365-AAZ/ --vfs-cache-mode off --daemon

# Attendre que le montage soit effectif
sleep 3
echo -n "  Vérification du montage... "
if check_mount "ASQSYS-365-AAZ/"; then
    echo -e "${GREEN}✓ Réussi${NC}"
else
    echo -e "${YELLOW}⚠ En cours (daemon lancé)${NC}"
fi
echo ""

# Montage 2: OneDrive-AZ-A-PERSO
log_message "${YELLOW}Étape 2/3: Montage de OneDrive-AZ-A-PERSO...${NC}"
echo "  Source: OneDrive-AZ-A-PERSO:"
echo "  Destination: PERSO-AZA/"

rclone mount OneDrive-AZ-A-PERSO: PERSO-AZA/ --vfs-cache-mode off --daemon

# Attendre que le montage soit effectif
sleep 3
echo -n "  Vérification du montage... "
if check_mount "PERSO-AZA/"; then
    echo -e "${GREEN}✓ Réussi${NC}"
else
    echo -e "${YELLOW}⚠ En cours (daemon lancé)${NC}"
fi
echo ""

# Montage 3: OneDrive-CTT-ASQSYS
log_message "${YELLOW}Étape 3/3: Montage de OneDrive-CTT-ASQSYS...${NC}"
echo "  Source: OneDrive-CTT-ASQSYS:"
echo "  Destination: ASQSYS-365-CONTACT/"

rclone mount OneDrive-CTT-ASQSYS: ASQSYS-365-CONTACT/ --vfs-cache-mode off --daemon

# Attendre que le montage soit effectif
sleep 3
echo -n "  Vérification du montage... "
if check_mount "ASQSYS-365-CONTACT/"; then
    echo -e "${GREEN}✓ Réussi${NC}"
else
    echo -e "${YELLOW}⚠ En cours (daemon lancé)${NC}"
fi
echo ""

# Résumé final
log_message "${GREEN}Tous les montages ont été initialisés!${NC}"
echo ""
echo -e "${BLUE}Résumé des montages:${NC}"
echo "  • ASQSYS-365-AAZ/ (OneDrive-AAZ-ASQSYS)"
echo "  • PERSO-AZA/ (OneDrive-AZ-A-PERSO)"
echo "  • ASQSYS-365-CONTACT/ (OneDrive-CTT-ASQSYS)"
echo ""
echo -e "${YELLOW}Note:${NC} Les montages rclone en mode daemon peuvent prendre quelques secondes"
echo "      supplémentaires pour être complètement opérationnels."
echo ""
echo -e "${BLUE}Pour vérifier l'état des montages:${NC} df -h | grep rclone"
echo -e "${BLUE}Pour démonter:${NC} fusermount -u <répertoire_de_montage>"
