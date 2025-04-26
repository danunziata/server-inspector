#!/bin/bash

# Script: generar.sh
# Descripción: Ejecuta los scripts que obtienen la información y el script hardware_detector.py, guarda los resultado en archivos JSON.

bash scripts/microprocesador.sh | python3 scripts/hardware_detector.py
bash scripts/gestion_energetica.sh | python3 scripts/hardware_detector.py