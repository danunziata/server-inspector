#!/bin/bash

# Script: generar.sh
# Descripción: Ejecuta los scripts que obtienen la información y el script hardware_detector.py, guarda los resultado en archivos JSON.

# Verificar permisos de superusuario
if [ "$(id -u)" -ne 0 ]; then
    echo "ADVERTENCIA: Algunos scripts requieren permisos de superusuario para obtener información completa."
    echo "La información de memoria RAM y otros detalles pueden estar incompletos."
    echo "Para obtener información completa, ejecute este script con sudo: sudo $0"
    echo ""
    echo "¿Desea continuar sin permisos de superusuario? (s/n)"
    read respuesta
    if [ "$respuesta" != "s" ]; then
        echo "Saliendo..."
        exit 1
    fi
fi

# Crear directorio para archivos temporales si no existe
mkdir -p tmp

# Ejecutar scripts y guardar salida en archivos temporales
echo "Obteniendo información del microprocesador..."
bash scripts/microprocesador.sh > tmp/microprocesador.txt
python3 scripts/hardware_detector.py < tmp/microprocesador.txt

echo "Obteniendo información de gestión energética..."
bash scripts/gestion_energetica.sh > tmp/gestion_energetica.txt
python3 scripts/hardware_detector.py < tmp/gestion_energetica.txt

echo "Obteniendo información de memoria RAM..."
bash scripts/mem_ram.sh > tmp/mem_ram.txt
python3 scripts/hardware_detector.py < tmp/mem_ram.txt

echo "Obteniendo información del sistema de almacenamiento..."
bash scripts/sistema_almacenamiento.sh > tmp/sistema_almacenamiento.txt
python3 scripts/hardware_detector.py < tmp/sistema_almacenamiento.txt

echo "Obteniendo información complementaria..."
bash scripts/info_complementaria.sh > tmp/info_complementaria.txt
python3 scripts/hardware_detector.py < tmp/info_complementaria.txt

echo "Obteniendo información de sensores de temperatura y energía..."
bash scripts/sensores_temperatura_y_energia.sh > tmp/sensores_temperatura_y_energia.txt
python3 scripts/sensor_detector.py < tmp/sensores_temperatura_y_energia.txt

# Limpiar archivos temporales
rm -rf tmp

# Cambiar permisos de la carpeta carac_server, para que el usuario pueda borrar la carpeta sin sudo
if [ "$(id -u)" -ne 0 ]; then
    sudo chown -R $USER:$USER carac_server
fi

echo "Proceso completado. Los archivos JSON se han generado en la carpeta 'carac_server'."