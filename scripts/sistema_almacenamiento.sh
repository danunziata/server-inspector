#!/bin/bash

# Script para recopilar información del sistema de almacenamiento
# Requiere permisos de sudo para smartctl y hdparm

echo "==== SISTEMA_ALMACENAMIENTO ===="

# Verificar comandos instalados
comandos_faltantes=()

if ! command -v lsblk &> /dev/null; then
    comandos_faltantes+=("lsblk")
fi

if ! command -v hdparm &> /dev/null; then
    comandos_faltantes+=("hdparm")
fi

if ! command -v smartctl &> /dev/null; then
    comandos_faltantes+=("smartctl")
fi

if ! command -v df &> /dev/null; then
    comandos_faltantes+=("df")
fi

# Mostrar advertencias si faltan comandos
if [ ${#comandos_faltantes[@]} -ne 0 ]; then
    echo "ADVERTENCIA: Los siguientes comandos no están instalados:"
    for cmd in "${comandos_faltantes[@]}"; do
        echo "- $cmd"
    done
    echo ""
    echo "Para instalar los comandos faltantes, ejecute:"
    echo "sudo apt-get install util-linux hdparm smartmontools coreutils"
    echo ""
fi

# Información básica de discos usando lsblk
if command -v lsblk &> /dev/null; then
    echo "==== lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT ===="
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
else
    echo "==== lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT ===="
    echo "No disponible - El comando lsblk no está instalado"
fi

# Información detallada de cada disco
if command -v lsblk &> /dev/null; then
    for disk in $(lsblk -d -o NAME | grep -v NAME); do
        echo "==== Disco: $disk ===="
        
        # Información de hdparm
        echo "==== hdparm -I /dev/$disk ===="
        if ! command -v hdparm &> /dev/null; then
            echo "No disponible - El comando hdparm no está instalado"
        elif [ "$(id -u)" -ne 0 ]; then
            echo "No disponible - Se requieren permisos de sudo"
        else
            hdparm -I /dev/$disk 2>/dev/null || echo "No disponible para este dispositivo"
        fi
        
        # Información SMART
        echo "==== smartctl -i /dev/$disk ===="
        if ! command -v smartctl &> /dev/null; then
            echo "No disponible - El comando smartctl no está instalado"
        elif [ "$(id -u)" -ne 0 ]; then
            echo "No disponible - Se requieren permisos de sudo"
        else
            smartctl -i /dev/$disk 2>/dev/null || echo "No disponible para este dispositivo"
        fi
        
        # Estado SMART básico
        echo "==== smartctl -H /dev/$disk ===="
        if ! command -v smartctl &> /dev/null; then
            echo "No disponible - El comando smartctl no está instalado"
        elif [ "$(id -u)" -ne 0 ]; then
            echo "No disponible - Se requieren permisos de sudo"
        else
            smartctl -H /dev/$disk 2>/dev/null || echo "No disponible para este dispositivo"
        fi
    done
fi

# Información de uso de particiones
if command -v df &> /dev/null; then
    echo "==== df -h ===="
    df -h
else
    echo "==== df -h ===="
    echo "No disponible - El comando df no está instalado"
fi 