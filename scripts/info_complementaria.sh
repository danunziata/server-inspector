#!/bin/bash

# Script para recopilar información complementaria del sistema

echo "==== INFO_COMPLEMENTARIA ===="

# Verificar comandos necesarios
comandos_faltantes=()
if ! command -v lsb_release &> /dev/null; then
    comandos_faltantes+=("lsb-release")
fi
if ! command -v uname &> /dev/null; then
    comandos_faltantes+=("uname")
fi
if ! command -v uptime &> /dev/null; then
    comandos_faltantes+=("uptime")
fi
if ! command -v tuned-adm &> /dev/null; then
    comandos_faltantes+=("tuned")
fi
if ! command -v hostnamectl &> /dev/null; then
    comandos_faltantes+=("hostnamectl")
fi

if [ ${#comandos_faltantes[@]} -ne 0 ]; then
    echo "ADVERTENCIA: Los siguientes comandos no están instalados:"
    for cmd in "${comandos_faltantes[@]}"; do
        echo "- $cmd"
    done
    echo "Para instalar los comandos faltantes, ejecute:"
    echo "sudo apt-get install lsb-release util-linux tuned systemd"
    echo ""
fi

# Distribución y versión
if command -v lsb_release &> /dev/null; then
    echo "==== lsb_release -a ===="
    lsb_release -a
else
    echo "==== lsb_release -a ===="
    echo "No disponible - El comando lsb_release no está instalado"
fi

# Kernel activo
if command -v uname &> /dev/null; then
    echo "==== uname -a ===="
    uname -a
else
    echo "==== uname -a ===="
    echo "No disponible - El comando uname no está instalado"
fi

# Uptime
if command -v uptime &> /dev/null; then
    echo "==== uptime ===="
    uptime
else
    echo "==== uptime ===="
    echo "No disponible - El comando uptime no está instalado"
fi

# Estado de tuned
if command -v tuned-adm &> /dev/null; then
    echo "==== tuned-adm active ===="
    tuned-adm active
else
    echo "==== tuned-adm active ===="
    echo "No disponible - El comando tuned-adm no está instalado"
fi

# Hostname, arquitectura, etc.
if command -v hostnamectl &> /dev/null; then
    echo "==== hostnamectl ===="
    hostnamectl
else
    echo "==== hostnamectl ===="
    echo "No disponible - El comando hostnamectl no está instalado"
fi 