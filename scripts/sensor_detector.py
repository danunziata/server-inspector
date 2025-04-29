import sys
import json
import re
import os

# Leer la salida del script desde stdin o desde un archivo pasado como argumento
if len(sys.argv) > 1:
    with open(sys.argv[1], 'r') as f:
        data = f.read()
else:
    data = sys.stdin.read()

# --- SENSORES DE TEMPERATURA Y ENERGÍA ---
if '==== SENSORES_TEMPERATURA_Y_ENERGIA ====' in data:
    sensores = {}
    # lm-sensors
    sensors_match = re.search(r'==== sensors ====(.*?)(====|$)', data, re.DOTALL)
    if sensors_match and 'No disponible' not in sensors_match.group(1):
        sensores['lm_sensors'] = sensors_match.group(1).strip()
    # /sys/class/hwmon/
    hwmon_match = re.search(r'==== /sys/class/hwmon/ ====(.*?)(====|$)', data, re.DOTALL)
    if hwmon_match:
        sensores['sys_class_hwmon'] = hwmon_match.group(1).strip()
    # /sys/class/thermal/
    thermal_match = re.search(r'==== /sys/class/thermal/ ====(.*?)(====|$)', data, re.DOTALL)
    if thermal_match:
        sensores['sys_class_thermal'] = thermal_match.group(1).strip()
    # /sys/class/powercap/
    powercap_match = re.search(r'==== /sys/class/powercap/ ====(.*?)(====|$)', data, re.DOTALL)
    if powercap_match:
        sensores['sys_class_powercap'] = powercap_match.group(1).strip()
    # /proc/acpi/
    acpi_match = re.search(r'==== /proc/acpi/ ====(.*?)(====|$)', data, re.DOTALL)
    if acpi_match:
        sensores['proc_acpi'] = acpi_match.group(1).strip()
    # /proc/driver/
    driver_match = re.search(r'==== /proc/driver/ ====(.*?)(====|$)', data, re.DOTALL)
    if driver_match:
        sensores['proc_driver'] = driver_match.group(1).strip()
    salida_sensores = {'sensores_temperatura_y_energia': sensores}
    carpeta = 'carac_server'
    os.makedirs(carpeta, exist_ok=True)
    ruta_archivo = os.path.join(carpeta, 'sensores_temperatura_y_energia.json')
    with open(ruta_archivo, 'w', encoding='utf-8') as f:
        json.dump(salida_sensores, f, indent=2, ensure_ascii=False)