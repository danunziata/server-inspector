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