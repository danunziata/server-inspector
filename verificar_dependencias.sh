#!/bin/bash

# Script para verificar todas las dependencias necesarias para server-inspector
# Muestra un aviso y el comando para instalarlas si falta alguna

DEPENDENCIAS=(
    bash
    python3
    lsb_release
    lsblk
    hdparm
    smartctl
    df
    sensors
    sensors-detect
    tuned-adm
    hostnamectl
    lshw
    inxi
    dmidecode
)

FALTANTES=()

for cmd in "${DEPENDENCIAS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        FALTANTES+=("$cmd")
    fi
done

if [ ${#FALTANTES[@]} -eq 0 ]; then
    echo "Todas las dependencias necesarias están instaladas."
else
    echo "ADVERTENCIA: Faltan las siguientes dependencias/comandos en el sistema:"
    for dep in "${FALTANTES[@]}"; do
        echo "- $dep"
    done
    echo ""
    # Mapeo de comandos a paquetes
    declare -A MAPEO
    MAPEO=(
        [lsb_release]="lsb-release"
        [lsblk]="util-linux"
        [hdparm]="hdparm"
        [smartctl]="smartmontools"
        [df]="coreutils"
        [sensors]="lm-sensors"
        [sensors-detect]="lm-sensors"
        [tuned-adm]="tuned"
        [hostnamectl]="systemd"
        [lshw]="lshw"
        [inxi]="inxi"
        [dmidecode]="dmidecode"
        [python3]="python3"
        [bash]="bash"
    )
    # Construir lista de paquetes únicos
    PAQUETES=()
    for dep in "${FALTANTES[@]}"; do
        pkg="${MAPEO[$dep]}"
        if [[ ! " ${PAQUETES[@]} " =~ " $pkg " ]]; then
            PAQUETES+=("$pkg")
        fi
    done
    echo "Puedes instalarlas en sistemas basados en Debian/Ubuntu con:"
    echo "sudo apt-get install ${PAQUETES[*]}"
fi 