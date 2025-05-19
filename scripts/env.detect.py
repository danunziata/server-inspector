import re

# Leer la salida del archivo
with open('sensors_report.txt', 'r', encoding='utf-8') as f:
    lines = f.readlines()

sensor_paths = {}
contador_tipo = {}

# Expresiones regulares para detectar paths y tipo de sensor
regex_sensor = re.compile(r'Sensor: ([^ ]+) \(([^)]*)\)')
regex_energia = re.compile(r'RAPL ([^:]+): ([^ ]+)')
regex_freq = re.compile(r'CPU\d+: ([^ ]+)')

# Buscar sensores de temperatura
for line in lines:
    m = regex_sensor.search(line)
    if m:
        path = m.group(1)
        label = m.group(2).strip().replace(' ', '_').replace('-', '_').lower()
        tipo = 'temp'
        if not label:
            label = 'temp'
        nombre = f'{tipo}_{label}'
        # Asegurar unicidad
        if nombre in sensor_paths:
            contador_tipo[nombre] = contador_tipo.get(nombre, 1) + 1
            nombre = f'{nombre}_{contador_tipo[nombre]}'
        sensor_paths[nombre] = path
    # Sensores de energía
    m2 = regex_energia.search(line)
    if m2:
        label = m2.group(1).strip().replace(' ', '_').replace('-', '_').lower()
        path = m2.group(2)
        tipo = 'energy'
        nombre = f'{tipo}_{label}'
        if nombre in sensor_paths:
            contador_tipo[nombre] = contador_tipo.get(nombre, 1) + 1
            nombre = f'{nombre}_{contador_tipo[nombre]}'
        sensor_paths[nombre] = path
    # Sensores de frecuencia
    m3 = regex_freq.search(line)
    if m3:
        path = m3.group(1)
        cpu = re.search(r'CPU(\d+):', line)
        if cpu:
            nombre = f'freq_cpu{cpu.group(1)}'
        else:
            nombre = 'freq_cpu'
        if nombre in sensor_paths:
            contador_tipo[nombre] = contador_tipo.get(nombre, 1) + 1
            nombre = f'{nombre}_{contador_tipo[nombre]}'
        sensor_paths[nombre] = path

# Generar salida tipo bash
with open('paths.detected.sh', 'w', encoding='utf-8') as f:
    f.write('# Paths detectados automáticamente\n')
    for nombre, path in sensor_paths.items():
        f.write(f'{nombre}="{path}"\n')

print('Archivo paths.detected.sh generado con los paths detectados.') 