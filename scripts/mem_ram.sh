#!/bin/bash

# Script para recopilar información de la memoria RAM
# Requiere permisos de sudo para dmidecode

echo "==== MEMORIA_RAM ===="

# Información básica de memoria usando free
echo "==== free -h ===="
free -h

# Verificar si se tiene permisos de sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "ADVERTENCIA: Este script requiere permisos de sudo para ejecutar dmidecode."
    echo "La información detallada de los módulos de memoria no estará disponible."
    echo "Para obtener información completa, ejecute el script con sudo: sudo $0"
    echo "==== dmidecode -t memory ===="
    echo "No disponible - Se requieren permisos de sudo"
else
    # Información detallada de los módulos de memoria
    echo "==== dmidecode -t memory ===="
    dmidecode -t memory
fi

# Verificar permisos para lshw
if [ "$(id -u)" -ne 0 ]; then
    echo "==== lshw -class memory ===="
    echo "No disponible - Se requieren permisos de sudo"
else
    # Información adicional de hardware
    echo "==== lshw -class memory ===="
    lshw -class memory
fi 