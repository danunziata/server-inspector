import os
import json

def formatea_clave(clave):
    return clave.replace('_', ' ').capitalize()

def seccion_titulo(titulo, nivel=1):
    return f"{'#' * nivel} {titulo}\n\n"

def seccion_subtitulo(subtitulo, nivel=2):
    return f"{'#' * nivel} {subtitulo}\n\n"

def formatea_dict(dic, indent=0):
    md = ''
    for k, v in dic.items():
        clave = formatea_clave(k)
        if isinstance(v, dict):
            md += ' ' * indent + f'- **{clave}**:\n'
            md += formatea_dict(v, indent + 2)
        elif isinstance(v, list):
            # Si el campo es flags, lo imprime separado por comas, si no, lo hace en items
            if k == "flags":
                valores = ', '.join(str(item) for item in v)
                md += ' ' * indent + f'- **{clave}**: {valores}\n'
            else:
                md += ' ' * indent + f'- **{clave}**:\n'
                for i, item in enumerate(v):
                    if isinstance(item, dict):
                        md += ' ' * (indent + 2) + f'- {formatea_dict(item, indent + 4)}'
                    else:
                        md += ' ' * (indent + 2) + f'- {item}\n'
        else:
            md += ' ' * indent + f'- **{clave}**: {v}\n'
    return md

# Explicaciones por sección
explicaciones = {
    'microprocesador.json': "Esta sección describe el procesador principal (CPU) del servidor, incluyendo modelo, fabricante, cantidad de núcleos, hilos, frecuencias y características avanzadas. Es fundamental para conocer la capacidad de cómputo del sistema.",
    'gestion_energetica.json': "Aquí se detalla cómo el sistema gestiona el consumo energético del procesador, incluyendo gobernadores de frecuencia, perfiles activos y estados de ahorro de energía. Esto es relevante para optimizar el rendimiento y la eficiencia.",
    'mem_ram.json': "Se presenta la información sobre la memoria RAM instalada: cantidad total, módulos presentes, tipo, velocidad, fabricante y uso actual. La RAM es clave para el rendimiento en multitarea y aplicaciones exigentes.",
    'sistema_almacenamiento.json': "Incluye el listado de discos (HDD, SSD, NVMe), sus capacidades, tipo de interfaz, estado SMART y uso de particiones. El almacenamiento determina la capacidad y velocidad de acceso a los datos.",
    'info_complementaria.json': "Información general del sistema operativo, kernel, tiempo de actividad, perfil energético activo, hostname y arquitectura. Permite identificar el entorno y configuración base del servidor.",
    'sensores_temperatura_y_energia.json': "Lecturas de sensores de temperatura y energía del sistema: CPU, GPU, VRMs, chipset, y otros. Es útil para monitorear el estado térmico y energético, previniendo sobrecalentamientos o fallos.",
}

# Ruta de los JSON
carpeta = 'carac_server'
archivos = [f for f in os.listdir(carpeta) if f.endswith('.json')]

# Orden sugerido para el reporte
orden = [
    'microprocesador.json',
    'gestion_energetica.json',
    'mem_ram.json',
    'sistema_almacenamiento.json',
    'info_complementaria.json',
    'sensores_temperatura_y_energia.json',
]

contenido = ''
contenido += seccion_titulo('Reporte de Inspección del Servidor')

for archivo in orden:
    if archivo not in archivos:
        continue
    ruta = os.path.join(carpeta, archivo)
    with open(ruta, 'r', encoding='utf-8') as f:
        data = json.load(f)
    nombre = archivo.replace('.json','').replace('_',' ').capitalize()
    contenido += seccion_subtitulo(nombre)
    # Agregar explicación introductoria
    if archivo in explicaciones:
        contenido += f'> {explicaciones[archivo]}\n\n'
    # Mostrar de forma legible
    for k, v in data.items():
        if isinstance(v, dict):
            contenido += formatea_dict(v)
        elif isinstance(v, list):
            for item in v:
                contenido += formatea_dict(item)
        else:
            clave = formatea_clave(k)
            contenido += f'- **{clave}**: {v}\n'
    contenido += '\n'

# Guardar el reporte
with open('reporte.md', 'w', encoding='utf-8') as f:
    f.write(contenido)

print('Reporte generado: reporte.md') 