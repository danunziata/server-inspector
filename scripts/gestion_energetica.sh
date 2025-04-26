#!/bin/bash

# Script: gestion_energetica.sh
# Descripción: Recolecta información sobre la gestión energética del procesador para ser parseada y exportada a JSON.

# Marca para parsear con hardware_detector.py
echo "==== GESTION_ENERGETICA ===="
# Gobernador de frecuencia actual para cada CPU
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    if [ -f "$cpu/cpufreq/scaling_governor" ]; then
        echo "==== scaling_governor (${cpu##*/}) ===="
        cat "$cpu/cpufreq/scaling_governor"
    fi
    if [ -f "$cpu/cpufreq/scaling_available_governors" ]; then
        echo "==== scaling_available_governors (${cpu##*/}) ===="
        cat "$cpu/cpufreq/scaling_available_governors"
    fi
    if [ -f "$cpu/cpufreq/scaling_min_freq" ]; then
        echo "==== scaling_min_freq (${cpu##*/}) ===="
        cat "$cpu/cpufreq/scaling_min_freq"
    fi
    if [ -f "$cpu/cpufreq/scaling_max_freq" ]; then
        echo "==== scaling_max_freq (${cpu##*/}) ===="
        cat "$cpu/cpufreq/scaling_max_freq"
    fi
    # Estados P disponibles
    if [ -d "$cpu/cpufreq" ]; then
        echo "==== p_states (${cpu##*/}) ===="
        ls "$cpu/cpufreq" 2>/dev/null | grep '^stats' || echo "No disponible"
    fi
    # Estados C disponibles
    if [ -d "$cpu/cpuidle" ]; then
        echo "==== c_states (${cpu##*/}) ===="
        for cstate in "$cpu/cpuidle"/state*; do
            if [ -f "$cstate/name" ]; then
                echo -n "$(basename $cstate): "
                cat "$cstate/name"
            fi
        done
    fi
    echo "----"
done

# Perfil activo de tuned-adm
if command -v tuned-adm >/dev/null 2>&1; then
    echo "==== tuned-adm active ===="
    tuned-adm active
else
    echo "==== tuned-adm active ===="
    echo "tuned-adm no está instalado"
fi 