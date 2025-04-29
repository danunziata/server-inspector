#!/bin/bash

# Script para recopilar información de sensores de temperatura y energía

echo "==== SENSORES_TEMPERATURA_Y_ENERGIA ===="

# Verificar comandos necesarios
comandos_faltantes=()
if ! command -v sensors &> /dev/null; then
    comandos_faltantes+=("lm-sensors")
fi
if ! command -v sensors-detect &> /dev/null; then
    comandos_faltantes+=("sensors-detect")
fi

if [ ${#comandos_faltantes[@]} -ne 0 ]; then
    echo "ADVERTENCIA: Los siguientes comandos no están instalados:"
    for cmd in "${comandos_faltantes[@]}"; do
        echo "- $cmd"
    done
    echo "Para instalar los comandos faltantes, ejecute:"
    echo "sudo apt-get install lm-sensors"
    echo ""
fi

# Advertencia sobre sensors-detect
if command -v sensors-detect &> /dev/null; then
    echo "ADVERTENCIA: La ejecución de 'sensors-detect' puede requerir intervención del usuario y privilegios de superusuario."
    echo "Se recomienda ejecutarlo manualmente si nunca se ha hecho antes."
fi

# Lectura de sensores con lm-sensors
if command -v sensors &> /dev/null; then
    echo "==== sensors ===="
    sensors
else
    echo "==== sensors ===="
    echo "No disponible - El comando sensors no está instalado"
fi

# Lectura directa desde /sys/class/hwmon/
echo "==== /sys/class/hwmon/ ===="
for hwmon in /sys/class/hwmon/hwmon*; do
    if [ -d "$hwmon" ]; then
        echo "--- $hwmon ---"
        cat "$hwmon"/name 2>/dev/null
        grep . "$hwmon"/temp*_input 2>/dev/null
        grep . "$hwmon"/power*_input 2>/dev/null
    fi
done

# Lectura directa desde /sys/class/thermal/
echo "==== /sys/class/thermal/ ===="
for thermal in /sys/class/thermal/thermal_zone*; do
    if [ -d "$thermal" ]; then
        echo "--- $thermal ---"
        cat "$thermal"/type 2>/dev/null
        cat "$thermal"/temp 2>/dev/null
    fi
done

# Lectura directa desde /sys/class/powercap/
echo "==== /sys/class/powercap/ ===="
if [ -d /sys/class/powercap ]; then
    find /sys/class/powercap -type f -exec echo "--- {} ---" \; -exec cat {} \;
else
    echo "No disponible - No existe /sys/class/powercap"
fi

# Lectura directa desde /proc/acpi/
echo "==== /proc/acpi/ ===="
if [ -d /proc/acpi ]; then
    find /proc/acpi -type f -exec echo "--- {} ---" \; -exec cat {} \;
else
    echo "No disponible - No existe /proc/acpi"
fi

# Lectura directa desde /proc/driver/
echo "==== /proc/driver/ ===="
if [ -d /proc/driver ]; then
    find /proc/driver -type f -exec echo "--- {} ---" \; -exec cat {} \;
else
    echo "No disponible - No existe /proc/driver"
fi 