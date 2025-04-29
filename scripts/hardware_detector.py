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

# --- MICROPROCESADOR ---
if '==== MICROPROCESADOR ====' in data:
    micro = {}
    lscpu_match = re.search(r'==== lscpu ====(.*?)==== /proc/cpuinfo ====', data, re.DOTALL)
    lscpu = lscpu_match.group(1) if lscpu_match else ''
    for line in lscpu.splitlines():
        if 'Model name' in line:
            micro['modelo'] = line.split(':',1)[1].strip()
        if 'Vendor ID' in line or 'Vendor ID' in line:
            micro['fabricante'] = line.split(':',1)[1].strip()
        if 'CPU family' in line:
            micro['familia'] = line.split(':',1)[1].strip()
        if 'Core(s) per socket' in line:
            micro['nucleos_fisicos'] = int(line.split(':',1)[1].strip())
        if 'Thread(s) per core' in line:
            micro['hilos_por_nucleo'] = int(line.split(':',1)[1].strip())
        if 'CPU(s):' in line and 'NUMA' not in line:
            try:
                micro['nucleos_logicos'] = int(line.split(':',1)[1].strip())
            except:
                pass
        if 'CPU MHz' in line:
            valor = line.split(':',1)[1].strip().replace(',', '.')
            try:
                micro['frecuencia_base_mhz'] = float(valor)
            except ValueError:
                pass
        if 'CPU max MHz' in line:
            valor = line.split(':',1)[1].strip().replace(',', '.')
            try:
                micro['frecuencia_max_mhz'] = float(valor)
            except ValueError:
                pass
        if 'Flags' in line:
            micro['flags'] = line.split(':',1)[1].strip().split()
    dmi_match = re.search(r'==== dmidecode -t processor ====(.*?)(====|$)', data, re.DOTALL)
    dmi = dmi_match.group(1) if dmi_match else ''
    for line in dmi.splitlines():
        if 'Voltage:' in line:
            micro['voltaje'] = line.split(':',1)[1].strip()
        if 'External Clock:' in line:
            micro['reloj_externo'] = line.split(':',1)[1].strip()
        if 'Current Speed:' in line:
            micro['frecuencia_actual'] = line.split(':',1)[1].strip()
        if 'Max Speed:' in line:
            micro['frecuencia_maxima'] = line.split(':',1)[1].strip()
        if 'Family:' in line and not micro.get('familia'):
            micro['familia'] = line.split(':',1)[1].strip()
        if 'Manufacturer:' in line and not micro.get('fabricante'):
            micro['fabricante'] = line.split(':',1)[1].strip()
        if 'Version:' in line and not micro.get('modelo'):
            micro['modelo'] = line.split(':',1)[1].strip()
        if 'Core Count:' in line and not micro.get('nucleos_fisicos'):
            try:
                micro['nucleos_fisicos'] = int(line.split(':',1)[1].strip())
            except:
                pass
        if 'Thread Count:' in line and not micro.get('nucleos_logicos'):
            try:
                micro['nucleos_logicos'] = int(line.split(':',1)[1].strip())
            except:
                pass
        if 'Technology:' in line:
            micro['tecnologia_fabricacion'] = line.split(':',1)[1].strip()
    if 'flags' not in micro:
        cpuinfo_match = re.search(r'==== /proc/cpuinfo ====(.*?)==== dmidecode -t processor ====', data, re.DOTALL)
        cpuinfo = cpuinfo_match.group(1) if cpuinfo_match else ''
        for line in cpuinfo.splitlines():
            if line.startswith('flags'):
                micro['flags'] = line.split(':',1)[1].strip().split()
                break
    inxi_match = re.search(r'==== inxi -C ====(.*?)(====|$)', data, re.DOTALL)
    inxi = inxi_match.group(1) if inxi_match else ''
    if inxi:
        for line in inxi.splitlines():
            if line.strip().startswith('CPU:'):
                if not micro.get('modelo'):
                    modelo = line.split(':',1)[1].split('(')[0].strip()
                    micro['modelo'] = modelo
                if not micro.get('fabricante'):
                    if 'Intel' in line:
                        micro['fabricante'] = 'Intel'
                    elif 'AMD' in line:
                        micro['fabricante'] = 'AMD'
                    elif 'ARM' in line:
                        micro['fabricante'] = 'ARM'
                import re as _re
                m = _re.search(r'(\d+)[- ]core', line)
                if m and not micro.get('nucleos_fisicos'):
                    micro['nucleos_fisicos'] = int(m.group(1))
            if 'speed:' in line:
                m = re.search(r'speed: ([\d.,]+) MHz', line)
                if m and not micro.get('frecuencia_base_mhz'):
                    try:
                        micro['frecuencia_base_mhz'] = float(m.group(1).replace(',', '.'))
                    except ValueError:
                        pass
                m2 = re.search(r'min/max: ([\d.,]+)/([\d.,]+) MHz', line)
                if m2:
                    if not micro.get('frecuencia_base_mhz'):
                        try:
                            micro['frecuencia_base_mhz'] = float(m2.group(1).replace(',', '.'))
                        except ValueError:
                            pass
                    if not micro.get('frecuencia_max_mhz'):
                        try:
                            micro['frecuencia_max_mhz'] = float(m2.group(2).replace(',', '.'))
                        except ValueError:
                            pass
    salida = {'microprocesador': micro}
    carpeta = 'carac_server'
    os.makedirs(carpeta, exist_ok=True)
    ruta_archivo = os.path.join(carpeta, 'microprocesador.json')
    with open(ruta_archivo, 'w', encoding='utf-8') as f:
        json.dump(salida, f, indent=2, ensure_ascii=False)

# --- GESTION ENERGETICA ---
if '==== GESTION_ENERGETICA ====' in data:
    gestion = {}
    cpus = {}
    cpu_blocks = re.split(r'----\s*', data)
    for block in cpu_blocks:
        cpu_match = re.search(r'scaling_governor \((cpu\d+)\)', block)
        if cpu_match:
            cpu_id = cpu_match.group(1)
            cpus[cpu_id] = {}
            m = re.search(r'scaling_governor \(%s\) ====\n([\w-]+)' % cpu_id, block)
            if m:
                cpus[cpu_id]['gobernador_actual'] = m.group(1)
            m = re.search(r'scaling_available_governors \(%s\) ====\n([\w\s-]+)' % cpu_id, block)
            if m:
                cpus[cpu_id]['gobernadores_disponibles'] = m.group(1).split()
            m = re.search(r'scaling_min_freq \(%s\) ====\n(\d+)' % cpu_id, block)
            if m:
                cpus[cpu_id]['frecuencia_min'] = int(m.group(1))
            m = re.search(r'scaling_max_freq \(%s\) ====\n(\d+)' % cpu_id, block)
            if m:
                cpus[cpu_id]['frecuencia_max'] = int(m.group(1))
            m = re.search(r'p_states \(%s\) ====\n([\w\s-]+)' % cpu_id, block)
            if m:
                p_states = [x for x in m.group(1).split() if x != 'No' and x != 'disponible']
                cpus[cpu_id]['p_states'] = p_states if p_states else None
            c_states = []
            cstate_matches = re.findall(r'(state\d+):\s*(\w+)', block)
            for c, name in cstate_matches:
                c_states.append({'id': c, 'nombre': name})
            if c_states:
                cpus[cpu_id]['c_states'] = c_states
    gestion['cpus'] = cpus
    m = re.search(r'==== tuned-adm active ====(.*?)$', data, re.DOTALL)
    if m:
        perfil = m.group(1).strip().replace('\n',' ')
        gestion['tuned_adm'] = perfil
    salida_gestion = {'gestion_energetica': gestion}
    carpeta = 'carac_server'
    os.makedirs(carpeta, exist_ok=True)
    ruta_archivo = os.path.join(carpeta, 'gestion_energetica.json')
    with open(ruta_archivo, 'w', encoding='utf-8') as f:
        json.dump(salida_gestion, f, indent=2, ensure_ascii=False)

# --- MEMORIA RAM ---
if '==== MEMORIA_RAM ====' in data:
    memoria = {}
    modulos = []
    
    # Parsear información de free
    free_match = re.search(r'==== free -h ====(.*?)==== dmidecode', data, re.DOTALL)
    if free_match:
        free_output = free_match.group(1)
        for line in free_output.splitlines():
            if 'Mem:' in line:
                parts = line.split()
                memoria['total'] = parts[1]
                memoria['usada'] = parts[2]
                memoria['libre'] = parts[3]
                memoria['compartida'] = parts[4]
                memoria['buff_cache'] = parts[5]
                memoria['disponible'] = parts[6]
            elif 'Swap:' in line:
                parts = line.split()
                memoria['swap_total'] = parts[1]
                memoria['swap_usado'] = parts[2]
                memoria['swap_libre'] = parts[3]

    # Parsear información de dmidecode
    dmi_match = re.search(r'==== dmidecode -t memory ====(.*?)==== lshw', data, re.DOTALL)
    if dmi_match:
        dmi_output = dmi_match.group(1)
        current_module = {}
        for line in dmi_output.splitlines():
            if 'Memory Device' in line:
                if current_module:
                    modulos.append(current_module)
                current_module = {}
            elif 'Size:' in line and 'No Module Installed' not in line:
                current_module['capacidad'] = line.split(':')[1].strip()
            elif 'Type:' in line:
                current_module['tipo'] = line.split(':')[1].strip()
            elif 'Speed:' in line:
                current_module['velocidad'] = line.split(':')[1].strip()
            elif 'Manufacturer:' in line:
                current_module['fabricante'] = line.split(':')[1].strip()
            elif 'Serial Number:' in line:
                current_module['numero_serie'] = line.split(':')[1].strip()
            elif 'Locator:' in line:
                current_module['ubicacion'] = line.split(':')[1].strip()
        
        if current_module:
            modulos.append(current_module)

    # Parsear información de lshw
    lshw_match = re.search(r'==== lshw -class memory ====(.*?)$', data, re.DOTALL)
    if lshw_match:
        lshw_output = lshw_match.group(1)
        for line in lshw_output.splitlines():
            if 'description:' in line and 'System Memory' in line:
                memoria['descripcion'] = line.split(':')[1].strip()
            elif 'physical id:' in line:
                memoria['id_fisico'] = line.split(':')[1].strip()
            elif 'size:' in line:
                memoria['tamanio_total'] = line.split(':')[1].strip()

    memoria['modulos'] = modulos
    salida_memoria = {'memoria_ram': memoria}
    
    carpeta = 'carac_server'
    os.makedirs(carpeta, exist_ok=True)
    ruta_archivo = os.path.join(carpeta, 'mem_ram.json')
    with open(ruta_archivo, 'w', encoding='utf-8') as f:
        json.dump(salida_memoria, f, indent=2, ensure_ascii=False)

# --- SISTEMA DE ALMACENAMIENTO ---
if '==== SISTEMA_ALMACENAMIENTO ====' in data:
    almacenamiento = {}
    discos = []
    
    # Parsear información de lsblk
    lsblk_match = re.search(r'==== lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT ====(.*?)(==== Disco:|==== df -h)', data, re.DOTALL)
    if lsblk_match:
        lsblk_output = lsblk_match.group(1)
        current_disk = {}
        for line in lsblk_output.splitlines():
            if line.strip() and not line.startswith('NAME'):
                parts = line.split()
                if len(parts) >= 5:
                    current_disk = {
                        'nombre': parts[0],
                        'tamanio': parts[1],
                        'tipo': parts[2],
                        'sistema_archivos': parts[3],
                        'punto_montaje': parts[4] if len(parts) > 4 else ''
                    }
                    discos.append(current_disk)

    # Parsear información de cada disco
    disk_blocks = re.split(r'==== Disco: (\w+) ====', data)
    for i in range(1, len(disk_blocks), 2):
        disk_name = disk_blocks[i]
        disk_info = disk_blocks[i+1]
        
        # Encontrar el disco correspondiente en la lista
        disk = next((d for d in discos if d['nombre'] == disk_name), None)
        if not disk:
            disk = {'nombre': disk_name}
            discos.append(disk)
        
        # Parsear información de hdparm
        hdparm_match = re.search(r'==== hdparm -I /dev/\w+ ====(.*?)==== smartctl', disk_info, re.DOTALL)
        if hdparm_match and 'No disponible' not in hdparm_match.group(1):
            hdparm_output = hdparm_match.group(1)
            for line in hdparm_output.splitlines():
                if 'Model Number:' in line:
                    disk['modelo'] = line.split(':', 1)[1].strip()
                elif 'Serial Number:' in line:
                    disk['numero_serie'] = line.split(':', 1)[1].strip()
                elif 'Transport:' in line:
                    disk['interfaz'] = line.split(':', 1)[1].strip()
                elif 'Device type:' in line:
                    disk['tipo_dispositivo'] = line.split(':', 1)[1].strip()
        
        # Parsear información de smartctl
        smart_info_match = re.search(r'==== smartctl -i /dev/\w+ ====(.*?)==== smartctl -H', disk_info, re.DOTALL)
        if smart_info_match and 'No disponible' not in smart_info_match.group(1):
            smart_info = smart_info_match.group(1)
            for line in smart_info.splitlines():
                if 'Device Model:' in line:
                    disk['modelo'] = line.split(':', 1)[1].strip()
                elif 'Serial Number:' in line:
                    disk['numero_serie'] = line.split(':', 1)[1].strip()
                elif 'User Capacity:' in line:
                    disk['capacidad'] = line.split(':', 1)[1].strip()
                elif 'Rotation Rate:' in line:
                    disk['velocidad_rotacion'] = line.split(':', 1)[1].strip()
        
        # Parsear estado SMART
        smart_health_match = re.search(r'==== smartctl -H /dev/\w+ ====(.*?)(====|$)', disk_info, re.DOTALL)
        if smart_health_match and 'No disponible' not in smart_health_match.group(1):
            smart_health = smart_health_match.group(1)
            if 'PASSED' in smart_health:
                disk['estado_smart'] = 'OK'
            elif 'FAILED' in smart_health:
                disk['estado_smart'] = 'FALLIDO'
            else:
                disk['estado_smart'] = 'DESCONOCIDO'
    
    # Parsear información de uso de particiones
    df_match = re.search(r'==== df -h ====(.*?)$', data, re.DOTALL)
    if df_match:
        df_output = df_match.group(1)
        particiones = []
        for line in df_output.splitlines():
            if line.strip() and not line.startswith('Filesystem'):
                parts = line.split()
                if len(parts) >= 6:
                    particion = {
                        'sistema_archivos': parts[0],
                        'tamanio': parts[1],
                        'usado': parts[2],
                        'disponible': parts[3],
                        'uso_porcentual': parts[4],
                        'punto_montaje': parts[5]
                    }
                    particiones.append(particion)
        almacenamiento['particiones'] = particiones

    almacenamiento['discos'] = discos
    salida_almacenamiento = {'sistema_almacenamiento': almacenamiento}
    
    carpeta = 'carac_server'
    os.makedirs(carpeta, exist_ok=True)
    ruta_archivo = os.path.join(carpeta, 'sistema_almacenamiento.json')
    with open(ruta_archivo, 'w', encoding='utf-8') as f:
        json.dump(salida_almacenamiento, f, indent=2, ensure_ascii=False)