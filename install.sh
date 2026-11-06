#!/usr/bin/env bash
# ============================================================
#  install.sh — Installe la configuration Hyprland sur un Arch
# ============================================================
#  Usage :
#     ./install.sh                 # installation complète
#     ./install.sh --skip-packages # config seulement (paquets déjà là)
#     ./install.sh --help
#
#  Le script :
#   1. vérifie qu'on est sur Arch Linux et récupère sudo
#   2. sauvegarde les configs existantes (~/.config-backup-AAAAmmjj-HHMMSS)
#   3. installe les paquets listés dans packages.txt
#   4. copie config/ dans ~/.config/
#   5. règle les scripts exécutables + police d'icônes Nerd Font
#   6. active Bluetooth
#   7. propose (optionnel) de passer la locale/clavier en français
#   8. recharge Hyprland si la session tourne
# ============================================================

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.config-backup-$STAMP"
SKIP_PACKAGES=0
CONFIG_DIRS=(hypr waybar dunst kitty fontconfig)

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
die()   { printf '\033[1;31m  ✗ %s\033[0m\n' "$*" >&2; exit 1; }

usage() {
    cat <<'EOF'
install.sh — installe la configuration Hyprland sur Arch Linux

Usage :
    ./install.sh                 installation complète (paquets + configs)
    ./install.sh --skip-packages configs seulement (paquets déjà installés)
    ./install.sh --help          affiche cette aide

Le script sauvegarde d'abord ~/.config/{hypr,waybar,dunst,kitty,fontconfig}
dans ~/.config-backup-AAAAmmjj-HHMMSS, puis installe les paquets de
packages.txt, copie config/ dans ~/.config/, active Bluetooth et propose
(optionnel) de passer la locale/clavier en français.
EOF
    exit 0
}

for arg in "$@"; do
    case "$arg" in
        --skip-packages) SKIP_PACKAGES=1 ;;
        -h|--help)       usage ;;
        *) die "Option inconnue : $arg (voir --help)" ;;
    esac
done

# ------------------------------------------------------------
# 1. Vérifications
# ------------------------------------------------------------
[ "$EUID" -eq 0 ] && die "Ne lance pas ce script en root. Lance-le avec ton utilisateur normal (il appellera sudo)."
command -v pacman >/dev/null 2>&1 || die "Ce script cible Arch Linux (pacman introuvable)."
[ -f "$ROOT/packages.txt" ] || die "packages.txt introuvable à côté du script."
[ -d "$ROOT/config" ] || die "Dossier config/ introuvable."

info "Demande d'autorisation sudo (mot de passe administrateur)…"
sudo -v || die "Autorisation sudo refusée."

# ------------------------------------------------------------
# 2. Sauvegarde
# ------------------------------------------------------------
info "Sauvegarde des configurations existantes dans :"
echo "    $BACKUP"
mkdir -p "$BACKUP"
for d in "${CONFIG_DIRS[@]}"; do
    if [ -e "$HOME/.config/$d" ]; then
        cp -a "$HOME/.config/$d" "$BACKUP/" 2>/dev/null || true
        ok "~/.config/$d sauvegardé"
    fi
done

# ------------------------------------------------------------
# 3. Paquets
# ------------------------------------------------------------
if [ "$SKIP_PACKAGES" -eq 0 ]; then
    mapfile -t PKGS < <(grep -vE '^\s*#|^\s*$' "$ROOT/packages.txt")
    info "Synchronisation + installation de ${#PKGS[@]} paquets…"
    sudo pacman -Syu --needed --noconfirm "${PKGS[@]}"
    ok "Paquets installés"
else
    warn "Installation des paquets ignorée (--skip-packages)"
fi

# ------------------------------------------------------------
# 4. Copie des configurations
# ------------------------------------------------------------
info "Copie des configurations dans ~/.config/…"
mkdir -p "$HOME/.config"
for d in "${CONFIG_DIRS[@]}"; do
    [ -d "$ROOT/config/$d" ] || continue
    rm -rf "${HOME:?}/.config/$d"
    mkdir -p "$HOME/.config/$d"
    cp -a "$ROOT/config/$d/." "$HOME/.config/$d/"
    ok "~/.config/$d"
done

# Scripts exécutables
chmod +x "$HOME/.config/waybar/"*.sh 2>/dev/null || true

# ------------------------------------------------------------
# 5. Police d'icônes Nerd Font + dossiers utilisateur
# ------------------------------------------------------------
info "Configuration des polices et dossiers utilisateur…"
mkdir -p "$HOME/.config/fontconfig/conf.d"
if [ -f /usr/share/fontconfig/conf.avail/10-nerd-font-symbols.conf ]; then
    ln -sf /usr/share/fontconfig/conf.avail/10-nerd-font-symbols.conf \
        "$HOME/.config/fontconfig/conf.d/10-nerd-font-symbols.conf"
    ok "Fallback Nerd Font activé"
else
    warn "10-nerd-font-symbols.conf absent (paquet ttf-nerd-fonts-symbols ?)"
fi
fc-cache -f >/dev/null 2>&1 || true
command -v xdg-user-dirs-update >/dev/null 2>&1 && xdg-user-dirs-update || true

# ------------------------------------------------------------
# 6. Services
# ------------------------------------------------------------
info "Activation du Bluetooth…"
if sudo systemctl enable --now bluetooth >/dev/null 2>&1; then
    ok "bluetooth actif"
else
    warn "Impossible d'activer bluetooth (pas d'adaptateur ?)"
fi

# Évite le doublon d'icône Bluetooth : le module Waybar suffit
systemctl --user mask --now blueman-applet.service >/dev/null 2>&1 || true

# ------------------------------------------------------------
# 7. Locale / clavier français (optionnel)
# ------------------------------------------------------------
CURRENT_LANG="$(sed -n 's/^LANG=//p' /etc/locale.conf 2>/dev/null || true)"
if [ "$CURRENT_LANG" != "fr_FR.UTF-8" ]; then
    warn "La locale système n'est pas fr_FR.UTF-8 (actuelle : ${CURRENT_LANG:-inconnue})"
    read -r -p "    Passer le système en français + clavier fr ? [o/N] " REPLY </dev/tty || REPLY="n"
    if [[ "$REPLY" =~ ^[oOyY]$ ]]; then
        sudo sed -i 's/^#\s*fr_FR\.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen
        grep -q '^fr_FR\.UTF-8 UTF-8' /etc/locale.gen || \
            echo 'fr_FR.UTF-8 UTF-8' | sudo tee -a /etc/locale.gen >/dev/null
        sudo locale-gen
        echo 'LANG=fr_FR.UTF-8' | sudo tee /etc/locale.conf >/dev/null
        sudo localectl set-keymap fr
        sudo localectl set-x11-keymap fr
        ok "Locale fr_FR.UTF-8 + clavier fr configurés"
        warn "Une reconnexion complète est nécessaire pour que la langue s'applique partout."
    else
        warn "Locale/clavier laissés inchangés (pense à kb_layout dans hyprland.lua si besoin)."
    fi
fi

# ------------------------------------------------------------
# 8. Rechargement à chaud
# ------------------------------------------------------------
if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
    info "Hyprland détecté : rechargement…"
    hyprctl reload >/dev/null 2>&1 || true
    pkill -x waybar 2>/dev/null || true
    sleep 0.4
    setsid -f waybar >/dev/null 2>&1 || true
    ok "Configuration rechargée"
else
    warn "Hyprland ne tourne pas : la config s'appliquera à la prochaine session."
fi

echo
info "Installation terminée."
echo "    Sauvegarde : $BACKUP"
echo "    Si c'est une première installation : déconnecte-toi et reconnecte-toi."
