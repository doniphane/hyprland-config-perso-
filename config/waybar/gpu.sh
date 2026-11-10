#!/bin/sh
# Utilisation et température du GPU NVIDIA pour Waybar
line=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits | head -1)
usage=${line%%,*}
rest=${line#*,}
temp=${rest%%,*}
temp=${temp# }

class=gpu
[ "$temp" -gt 80 ] 2>/dev/null && class="gpu critical"

printf '{"text": "󰢮 %s%%", "tooltip": "GPU NVIDIA\\nUtilisation : %s %%\\nTempérature : %s °C", "class": "%s"}' "$usage" "$usage" "$temp" "$class"
