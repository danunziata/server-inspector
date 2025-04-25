# 📋 Requerimientos Funcionales y Técnicos  
**Proyecto:** Script de Caracterización de Hardware y Sensores del Servidor

---

## 🧭 Introducción  
Este documento detalla los requerimientos necesarios para el desarrollo de dos scripts independientes: uno para caracterizar el hardware y configuraciones energéticas del servidor, y otro para relevar sensores de temperatura y energía disponibles.  

Ambos scripts están destinados a ejecutarse en sistemas operativos basados en Linux, escritos en Python, Bash o una combinación, priorizando la portabilidad, legibilidad y facilidad de uso.

---

## 🎯 Objetivos del Sistema  
- Identificar las características físicas y de configuración energética del servidor.  
- Relevar sensores disponibles de temperatura y energía mediante `lm-sensors`.  
- Generar un reporte estructurado y legible para diagnóstico y optimización.

---

## 📂 Estructura de Scripts

- `hardware_detector.py` / `.sh`: Caracterización del hardware y configuración energética.  
- `sensor_detector.py` / `.sh`: Relevamiento de sensores térmicos y eléctricos.

---

## ✅ Requerimientos Funcionales

### 1. Microprocesador (Hardware Detector)
- Modelo, fabricante y familia del procesador.  
- Núcleos físicos y lógicos.  
- Frecuencia base y turbo (si aplica).  
- Flags relevantes (e.g., virtualización).  
- Tecnología de fabricación (opcional).  
- Herramientas: `lscpu`, `/proc/cpuinfo`, `dmidecode`.

### 2. Gestión Energética del Procesador (Hardware Detector)
- Gobernador de frecuencia actual (`performance`, `powersave`, etc.).  
- Políticas de escalado activas.  
- Estados P y C disponibles (si accesibles vía `/sys/`).  
- Perfil activo mediante `tuned-adm` (si está instalado).

### 3. Memoria RAM (Hardware Detector)
- Capacidad total instalada.  
- Número de módulos y sus características (capacidad, tipo, velocidad).  
- Fabricante y número de serie (`dmidecode`).  
- Estado actual: libre, usada, swap.

### 4. Sistema de Almacenamiento (Hardware Detector)
- Listado de discos conectados (HDD, SSD, NVMe).  
- Capacidad, tipo de interfaz, tipo de medio.  
- Modelo, fabricante, estado SMART básico.  
- Uso actual de cada partición.  
- Herramientas: `lsblk`, `smartctl`, `hdparm`.

### 5. Información Complementaria (Hardware Detector)
- Distribución Linux y versión.  
- Kernel activo.  
- Tiempo de actividad (`uptime`).  
- Estado de `tuned` o perfiles energéticos.  
- Hostname, arquitectura, etc.

---

### 6. Sensores de Temperatura y Energía (Sensor Detector)
- Integración con `lm-sensors`.  
- Ejecución de `sensors-detect` (con advertencia).  
- Lectura de sensores: CPU, GPU, VRMs, chipset, sensores de energía.  
- Presentación de valores con etiquetas y unidades.  
- Lectura directa desde:  
  - `/sys/class/hwmon/`  
  - `/sys/class/thermal/`  
  - `/sys/class/powercap/`  
  - `/proc/acpi/`  
  - `/proc/driver/`

---

## ⚙️ Requerimientos No Funcionales
- Scripts autocontenidos y portables.  
- Verificación de dependencias y sugerencias en caso de ausencia.  
- Formato de salida claro: JSON y/o Markdown.  
- Generación de reporte exportable a archivo.  
- Advertencia en caso de requerir `sudo` o permisos elevados.

---

## 🛠️ Herramientas Recomendadas  
- `lscpu`, `cpufreq-info`, `tuned-adm`  
- `dmidecode`, `free`, `top`, `vmstat`  
- `lsblk`, `smartctl`, `hdparm`  
- `sensors`, `sensors-detect` (`lm-sensors`)  
- `inxi` (opcional)  
- Acceso de lectura a `/proc/` y `/sys/`

---

## 📦 Entregables Esperados  
- Scripts ejecutables (`.py`, `.sh` o mixtos).  
- `README.md` con:  
  - Instrucciones de uso.  
  - Lista de herramientas necesarias.  
  - Recomendaciones sobre permisos y entorno.  
- Reporte estructurado (consola + exportación opcional).
