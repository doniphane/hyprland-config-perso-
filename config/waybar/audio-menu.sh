#!/bin/sh
# Menu de sélection de la sortie audio (Waybar custom/audio-out, clic gauche)
sel=$(pactl list sinks 2>/dev/null | awk '
    /^[[:space:]]*Name: / { name = $2 }
    /^[[:space:]]*Description: / {
        d = $0
        sub(/^[[:space:]]*Description: /, "", d)
        printf "%s\t%s\n", d, name
    }' | wofi --dmenu -p "Sortie audio")

[ -z "$sel" ] && exit 0

name=$(printf '%s' "$sel" | cut -f2)
[ -z "$name" ] && exit 0

pactl set-default-sink "$name"
# Déplace les flux audio déjà en cours vers la nouvelle sortie
for input in $(pactl list short sink-inputs 2>/dev/null | cut -f1); do
    pactl move-sink-input "$input" "$name" 2>/dev/null
done
