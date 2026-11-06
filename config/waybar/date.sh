#!/bin/sh
# Date en français pour Waybar (waybar n'applique pas la locale aux noms de jours/mois)
text=$(date '+%a %d %b')
cal3=$(cal -3 | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' | awk 'BEGIN { ORS="\\n" } { print }')
printf '{"text":"%s","tooltip":"<tt>%s</tt>"}\n' "$text" "$cal3"
