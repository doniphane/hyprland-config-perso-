#!/bin/sh
# Affiche la sortie audio par défaut (Waybar custom/audio-out)
sink=$(pactl get-default-sink 2>/dev/null)
desc=$(pactl list sinks 2>/dev/null | awk -v s="$sink" '
    /^[[:space:]]*Name: / { name = $2 }
    /^[[:space:]]*Description: / {
        d = $0
        sub(/^[[:space:]]*Description: /, "", d)
        if (name == s) { print d; exit }
    }')

if [ -z "$desc" ]; then
    desc=$(printf '%s' "$sink" | sed 's/alsa_output\.//; s/\.analog-stereo//; s/\./_/g')
fi

# Libellé compact pour la barre
case "$sink" in
    *bluez*)            label="Bluetooth" ;;
    *hdmi*|*displayport*) label="HDMI" ;;
    *analog-stereo*|*pci*) label="Interne" ;;
    *)                  label=$(printf '%s' "$desc" | cut -c1-18) ;;
esac

printf '{"text":"󰓃 %s","tooltip":"%s\\n%s"}\n' "$label" "$desc" "$sink"
