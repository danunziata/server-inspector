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

# Limpiar archivos temporales
rm -rf tmp

echo "Proceso completado. Los archivos JSON se han generado en la carpeta 'carac_server'."