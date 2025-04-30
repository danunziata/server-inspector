import os
import json

def seccion_titulo(titulo, nivel=1):
    return f"{'#' * nivel} {titulo}\n\n"

def seccion_subtitulo(subtitulo, nivel=2):
    return f"{'#' * nivel} {subtitulo}\n\n"

def formatea_dict(dic, indent=0):
    md = ''
    for k, v in dic.items():
        if isinstance(v, dict):
            md += ' ' * indent + f'- **{k}**:\n'
            md += formatea_dict(v, indent + 2)
        elif isinstance(v, list):
            md += ' ' * indent + f'- **{k}**:\n'
            for i, item in enumerate(v):
                if isinstance(item, dict):
                    md += ' ' * (indent + 2) + f'- {formatea_dict(item, indent + 4)}'
                else:
                    md += ' ' * (indent + 2) + f'- {item}\n'
        else:
            md += ' ' * indent + f'- **{k}**: {v}\n'
    return md

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
    # Mostrar de forma legible
    for k, v in data.items():
        if isinstance(v, dict):
            contenido += formatea_dict(v)
        elif isinstance(v, list):
            for item in v:
                contenido += formatea_dict(item)
        else:
            contenido += f'- **{k}**: {v}\n'
    contenido += '\n'

# Guardar el reporte
with open('reporte.md', 'w', encoding='utf-8') as f:
    f.write(contenido)

print('Reporte generado: reporte.md') 