#!/bin/bash

# Script: microprocesador.sh
# Descripción: Recolecta información del microprocesador para ser parseada posteriormente y exportada a JSON.
# Requiere sudo para obtener información completa de dmidecode.

# Marca para parsear con hardware_detector.py
echo "==== MICROPROCESADOR ===="
# --- Aviso sobre permisos ---
if ! sudo -n true 2>/dev/null; then
    echo "[ADVERTENCIA] Se recomienda ejecutar este script con 'sudo' para obtener información completa del procesador (especialmente con dmidecode)."
fi

echo "==== lscpu ===="
lscpu

echo "==== /proc/cpuinfo ===="
cat /proc/cpuinfo

echo "==== dmidecode -t processor ===="
if sudo -n true 2>/dev/null; then
    sudo dmidecode -t processor
else
    echo "[INFO] dmidecode requiere privilegios de superusuario. Ejecute el script con 'sudo' para obtener esta información."
fi

# Opcional: inxi -C (si está instalado)
if command -v inxi >/dev/null 2>&1; then
    echo "==== inxi -C ===="
    inxi -C
fi

# Nota: La salida de este script está pensada para ser parseada por otro script (por ejemplo, en Python) que generará el archivo JSON final. 