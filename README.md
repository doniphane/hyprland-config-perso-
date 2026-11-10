# Configuration Hyprland — prête à dupliquer

Configuration complète d'un bureau **Hyprland** sur Arch Linux : barre, fond
d'écran, notifications, verrouillage, presse-papiers, Bluetooth, audio, etc.
Le dossier est **autonome** : copie-le sur une clé USB, puis lance `install.sh`
sur la nouvelle machine.

> Testé avec **Hyprland 0.57.1** (configuration Lua `hyprland.lua`), Waybar 0.15,
> Hyprpaper 0.8, PipeWire/WirePlumber, `iwd` pour le Wi-Fi.

---

## 1. Contenu du dossier

```
hyprland-config/
├── install.sh              # script d'installation (à lancer)
├── packages.txt            # liste des paquets Arch à installer
├── README.md               # ce fichier
└── config/                 # configurations à copier dans ~/.config/
    ├── hypr/
    │   ├── hyprland.lua        # config principale (raccourcis, règles de fenêtres)
    │   ├── hyprland.conf       # autostart (polkitagent + hyprpaper)
    │   ├── hyprpaper.conf      # fond d'écran
    │   ├── hypridle.conf       # verrouillage auto (veille DÉSACTIVÉE)
    │   ├── hyprlock.conf       # écran de verrouillage
    │   └── hyprlauncher.conf   # lanceur d'applications
    ├── waybar/
    │   ├── config.jsonc        # modules de la barre
    │   ├── style.css           # thème sombre / accent cyan
    │   ├── date.sh             # date en français (+ calendrier)
    │   ├── audio-output.sh     # sortie audio affichée
    │   ├── audio-menu.sh       # menu de choix de sortie audio
    │   └── gpu.sh              # température / usage GPU
    ├── wlogout/
    │   ├── layout              # menu de session (verrouiller, éteindre…)
    │   └── style.css           # style assorti à la waybar
    ├── dunst/dunstrc           # notifications
    └── kitty/kitty.conf        # terminal
```

---

## 2. Prérequis

- **Arch Linux** (ou dérivé avec `pacman`), à jour : `sudo pacman -Syu`
- Accès `sudo`
- Pilotes graphiques installés (Mesa / Intel / AMD / NVIDIA)
- Une session Wayland fonctionnelle (SDDM, TTY, etc.)

---

## 3. Installation

```bash
cd hyprland-config
chmod +x install.sh
./install.sh
```

Puis **déconnecte-toi / reconnecte-toi** (ou lance `Hyprland`) pour la première
session.

Options :

```bash
./install.sh --skip-packages   # ne réinstalle rien, copie juste la config
./install.sh --help
```

### Ce que fait `install.sh`

1. Vérifie Arch + récupère `sudo`.
2. **Sauvegarde** `~/.config/{hypr,waybar,wlogout,dunst,kitty,fontconfig}` dans
   `~/.config-backup-AAAAmmjj-HHMMSS`.
3. Installe les paquets de `packages.txt` (`pacman -S --needed`).
4. Remplace les configs par celles du dossier.
5. Rend les scripts Waybar exécutables, active le fallback d'icônes Nerd Font
   et met à jour les dossiers utilisateur (`~/Documents`, `~/Images`…).
6. Active le service `bluetooth`.
7. Propose (optionnel) de passer la **locale et le clavier en français**.
8. Recharge Hyprland + Waybar si une session tourne.

---

## 4. Raccourcis clavier

> `SUPER` = touche Windows. Les chiffres correspondent à la **rangée AZERTY**
> (`& é " ' ( - è _ ç à`).

| Raccourci | Action |
|---|---|
| `SUPER + Q` | Terminal (kitty) |
| `SUPER + R` / `SUPER + Espace` | Lanceur d'applications |
| `SUPER + W` | Fermer la fenêtre / l'appli |
| `SUPER + Maj + W` | Fermer **de force** |
| `SUPER + C` | Fermer la fenêtre |
| `SUPER + E` | Gestionnaire de fichiers (Dolphin) |
| `SUPER + F` | Plein écran |
| `SUPER + V` | Fenêtre flottante |
| `SUPER + P` | Pseudo-tuilage |
| `SUPER + J` | Changer le sens du split (dwindle) |
| `SUPER + L` | Verrouiller la session |
| `SUPER + Maj + V` | Historique du presse-papiers |
| `SUPER + Maj + P` | Pipette de couleur (hyprpicker) |
| `Impr. écran` | Capture d'une région → presse-papiers |
| `SUPER + Impr. écran` | Capture de la fenêtre active |
| `SUPER + 1…0` | Aller au bureau 1…10 |
| `SUPER + Maj + 1…0` | Déplacer la fenêtre vers le bureau 1…10 |
| `SUPER + S` | Bureau spécial (scratchpad) |
| `SUPER + molette` | Bureau suivant / précédent |
| `SUPER + clic gauche` | Déplacer la fenêtre |
| `SUPER + clic droit` | Redimensionner la fenêtre |
| Touches volume / luminosité | Réglage direct |

---

## 5. Personnalisation rapide

### Fond d'écran
`~/.config/hypr/hyprpaper.conf` (Hyprpaper ≥ 0.8, syntaxe en bloc) :

```conf
splash = false
wallpaper {
    monitor =
    path = ~/font.png
    fit_mode = cover
}
```

> `monitor` vide = tous les écrans. Change `path` pour ton image, puis :
> `pkill -x hyprpaper; hyprpaper &`

### Barre
- Modules et cadence : `~/.config/waybar/config.jsonc`
- Couleurs / arrondis / transparence : `~/.config/waybar/style.css`
- Recharger : `pkill -x waybar; waybar &`
- Bouton ⏻ : ouvre **wlogout** (menu session). Layout : `~/.config/wlogout/layout`,
  style : `~/.config/wlogout/style.css`. Clic droit sur ⏻ = verrouillage direct.

### Clavier
Dans `~/.config/hypr/hyprland.lua`, section `input` :
```lua
kb_layout = "fr",   -- "us", "be", "de"…
```
Puis `hyprctl reload`.

### Verrouillage / veille
`~/.config/hypr/hypridle.conf`. La **mise en veille est volontairement
désactivée** ; pour la réactiver, décommente le listener `systemctl suspend`.

### Sortie audio
Clic gauche sur `󰓃 Interne` dans la barre → menu des sorties disponibles.
Pour ajouter une sortie par défaut : `pactl set-default-sink <nom>`.

---

## 6. Notes importantes

- **Réseau** : cette machine utilise `iwd` (pas NetworkManager). Le module
  Wi-Fi de Waybar lit l'interface, et un clic ouvre `impala` dans un terminal.
  Sur une autre machine avec **NetworkManager**, tout fonctionne aussi ; tu
  peux installer `network-manager-applet` et l'ajouter à l'autostart si tu
  veux une icône.
- **Hyprland ≥ 0.57** : la config est en **Lua** (`hyprland.lua`). Les versions
  plus anciennes utilisent `hyprland.conf` et ne liront pas ce fichier.
- **Waybar** n'applique pas la locale aux noms de jours/mois : c'est le rôle de
  `date.sh` (français).
- **Montage USB** : `udiskie` est lancé automatiquement (démonter via le
  gestionnaire de fichiers ou `udiskie-umount`).
- **Bluetooth** : clic sur l'icône 󰂯 → `blueman-manager` ; clic droit → couper.
  Le service `blueman-applet` est **masqué** pour éviter une seconde icône
  Bluetooth dans la barre. Pour le réactiver :
  `systemctl --user unmask --now blueman-applet.service`.

---

## 7. Restauration

Les anciennes configs sont dans `~/.config-backup-AAAAmmjj-HHMMSS` :

```bash
cp -a ~/.config-backup-*/hypr ~/.config/
cp -a ~/.config-backup-*/waybar ~/.config/
# etc.
hyprctl reload
```

---

## 8. Dépannage

| Problème | Solution |
|---|---|
| Pas de barre | `pgrep -x waybar || waybar` puis lire la sortie |
| Pas de fond d'écran | vérifier `monitor` dans `hyprpaper.conf` (`hyprctl monitors`) |
| Icônes carrées (□) | `fc-cache -f`, vérifier `ttf-nerd-fonts-symbols` |
| Pas de son | `wpctl status`, `pactl info`, vérifier `pipewire`/`wireplumber` |
| Écran noir après login | tester `Hyprland` depuis un TTY pour voir les logs |
| Clavier QWERTY | `kb_layout = "fr"` + `hyprctl reload` |
| Popup mot de passe absent | lancer `hyprpolkitagent` (déjà dans l'autostart) |
# hyprland-config-perso-
