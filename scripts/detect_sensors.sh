#!/bin/bash

# Script para detectar sensores disponibles para monitoreo de servidor
# Autor: Server Load Testing Team
# Descripción: Detecta sensores de temperatura, energía y frecuencia en el sistema
#              y genera un archivo de configuración recomendado

# Configuración de archivos de salida
OUTPUT_FILE="config.txt.recommended"
REPORT_FILE="sensors_report.txt"
REPORT_CPU_FILE="report_cpu.txt"
REPORT_FULL_FILE="report_full.txt"  # Nuevo archivo para el reporte completo

# Colores para salida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Función para escribir tanto en la consola como en el archivo de reporte
report() {
    echo -e "$@"  # Mostrar en consola con colores
    
    # Eliminar códigos de color para la versión guardada en archivo
    # Esto convierte cosas como '\033[0;32mTexto\033[0m' a 'Texto'
    clean_text=$(echo -e "$@" | sed 's/\x1B\[[0-9;]*[mK]//g')
    echo "$clean_text" >> "$REPORT_FILE"
    
    # También guardar una copia en el reporte completo, excepto para las líneas de comando
    if [[ ! "$clean_text" =~ ^\ *\$ ]]; then
        echo "$clean_text" >> "$REPORT_FULL_FILE"
    fi
}

# Función para escribir solo al archivo de reporte CPU
report_cpu() {
    # No mostramos en consola, solo guardamos en el archivo CPU
    clean_text=$(echo -e "$@" | sed 's/\x1B\[[0-9;]*[mK]//g')
    echo "$clean_text" >> "$REPORT_CPU_FILE"
}

# Inicializar los archivos de reporte (sin encabezado, directo al contenido)
echo "=== DETECTANDO SENSORES DEL SISTEMA ===" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "=== INFORMACIÓN DETALLADA DEL PROCESADOR ===" > "$REPORT_CPU_FILE"
echo "Fecha: $(date "+%Y-%m-%d %H:%M:%S")" >> "$REPORT_CPU_FILE"
echo "Host: $(hostname)" >> "$REPORT_CPU_FILE"
echo "" >> "$REPORT_CPU_FILE"

# Inicializar el reporte completo
echo "=== REPORTE COMPLETO DE DETECCIÓN DE SENSORES ===" > "$REPORT_FULL_FILE"
echo "Fecha: $(date "+%Y-%m-%d %H:%M:%S")" >> "$REPORT_FULL_FILE"
echo "Host: $(hostname)" >> "$REPORT_FULL_FILE"
echo "" >> "$REPORT_FULL_FILE"

# Encabezado del archivo de configuración
cat > "$OUTPUT_FILE" <<EOF
# Configuración optimizada para monitoreo basada en sensores disponibles
# Generado: $(date "+%Y-%m-%d")

EOF

# Función para comprobar si un valor es numérico
is_numeric() {
    if [[ $1 =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        return 0 # Es numérico
    else
        return 1 # No es numérico
    fi
}

# 0. Información del procesador
report "${BLUE}=== INFORMACIÓN DE CPU ===${NC}"

# Obtener modelo del procesador
cpu_model=$(grep -m 1 "model name" /proc/cpuinfo | cut -d ':' -f 2 | sed 's/^ *//')
report "${GREEN}Modelo de CPU:${NC} $cpu_model"
report_cpu "Modelo de CPU: $cpu_model"

# Contar sockets (CPUs físicas)
num_sockets=$(grep "physical id" /proc/cpuinfo | sort -u | wc -l)
if [ "$num_sockets" -eq 0 ]; then
    num_sockets=1  # En caso de que no se encuentre información de "physical id"
fi
report "${GREEN}Sockets:${NC} $num_sockets"
report_cpu "Sockets: $num_sockets"

# Contar núcleos físicos por socket
cores_per_socket=$(grep -m 1 "cpu cores" /proc/cpuinfo | cut -d ':' -f 2 | sed 's/^ *//')
if [ -z "$cores_per_socket" ]; then 
    cores_per_socket=1  # En caso de que no se encuentre información de "cpu cores"
fi
report "${GREEN}Núcleos físicos por socket:${NC} $cores_per_socket"
report_cpu "Núcleos físicos por socket: $cores_per_socket"

# Total de núcleos físicos
total_physical_cores=$((num_sockets * cores_per_socket))
report "${GREEN}Total de núcleos físicos:${NC} $total_physical_cores"
report_cpu "Total de núcleos físicos: $total_physical_cores"

# Contar núcleos lógicos (procesadores visibles al sistema)
logical_cores=$(grep -c ^processor /proc/cpuinfo)
report "${GREEN}Total de núcleos lógicos:${NC} $logical_cores"
report_cpu "Total de núcleos lógicos: $logical_cores"

# Calcular hilos por núcleo físico
if [ "$total_physical_cores" -gt 0 ]; then
    threads_per_core=$((logical_cores / total_physical_cores))
else
    threads_per_core=1
fi
report "${GREEN}Hilos por núcleo:${NC} $threads_per_core"
report_cpu "Hilos por núcleo: $threads_per_core"

# Determinar si Hyper-Threading/SMT está activo
ht_support="No soportado"
if [ "$threads_per_core" -gt 1 ]; then
    # Verificar si es Intel o AMD para usar la terminología correcta
    if grep -q "Intel" /proc/cpuinfo; then
        ht_support="Soportado (Hyper-Threading)"
    elif grep -q "AMD" /proc/cpuinfo; then
        ht_support="Soportado (SMT)"
    else
        ht_support="Soportado"
    fi
fi
report "${GREEN}Hyper-Threading / SMT:${NC} $ht_support"
report_cpu "Hyper-Threading / SMT: $ht_support"

# También podemos verificar si el CPU tiene las extensiones HTT o smt
if grep -q "flags" /proc/cpuinfo; then
    cpu_flags=$(grep -m 1 "flags" /proc/cpuinfo | cut -d ':' -f 2)
    if [[ "$cpu_flags" == *" ht "* ]]; then
        report "${YELLOW}Nota:${NC} La CPU tiene la extensión HT en sus flags"
        report_cpu "Nota: La CPU tiene la extensión HT en sus flags"
    fi
fi

# Añadir información más detallada del CPU al archivo report_cpu.txt
report_cpu "\n=== INFORMACIÓN DETALLADA DEL CPU ===" 

# Añadir detalles del fabricante y familia del CPU
if grep -q "vendor_id" /proc/cpuinfo; then
    vendor=$(grep -m 1 "vendor_id" /proc/cpuinfo | cut -d ':' -f 2 | sed 's/^ *//')
    report_cpu "Fabricante del CPU: $vendor"
fi

if grep -q "cpu family" /proc/cpuinfo; then
    family=$(grep -m 1 "cpu family" /proc/cpuinfo | cut -d ':' -f 2 | sed 's/^ *//')
    report_cpu "Familia del CPU: $family"
fi

if grep -q "model\t" /proc/cpuinfo; then
    model=$(grep -m 1 "model\t" /proc/cpuinfo | cut -d ':' -f 2 | sed 's/^ *//')
    report_cpu "Modelo (número): $model"
fi

if grep -q "stepping" /proc/cpuinfo; then
    stepping=$(grep -m 1 "stepping" /proc/cpuinfo | cut -d ':' -f 2 | sed 's/^ *//')
    report_cpu "Stepping: $stepping"
fi

# Añadir información sobre caché del CPU
report_cpu "\n=== INFORMACIÓN DE CACHÉ ===" 
for cache_level in "cache size" "l1d cache" "l1i cache" "l2 cache" "l3 cache"; do
    if grep -q "$cache_level" /proc/cpuinfo; then
        cache_info=$(grep -m 1 "$cache_level" /proc/cpuinfo | cut -d ':' -f 2 | sed 's/^ *//')
        report_cpu "$(echo $cache_level | sed 's/^./\U&/g'): $cache_info"
    fi
done

# Añadir flags del CPU
if grep -q "flags" /proc/cpuinfo; then
    report_cpu "\n=== FLAGS DEL CPU ===" 
    
    # Verificar algunas extensiones importantes
    report_cpu "Extensiones importantes:"
    
    cpu_flags=$(grep -m 1 "flags" /proc/cpuinfo | cut -d ':' -f 2 | sed 's/^ *//')
    for flag in "mmx" "sse" "sse2" "sse3" "sse4_1" "sse4_2" "avx" "avx2" "avx512" "aes" "vmx" "svm" "ht" "lm" "nx" "pae"; do
        if [[ $cpu_flags == *" $flag "* ]]; then
            report_cpu "- $flag: Soportado"
        else
            report_cpu "- $flag: No soportado"
        fi
    done
    
    report_cpu "\nFlags completos: $cpu_flags"
fi

# Obtener información de la arquitectura del kernel
report_cpu "\n=== INFORMACIÓN DEL KERNEL ===" 
report_cpu "Arquitectura: $(uname -m)"
report_cpu "Kernel: $(uname -r)"
report_cpu "Sistema operativo: $(uname -o)"

# Agregar información de CPU a la configuración recomendada
echo -e "# Información del CPU detectado" >> "$OUTPUT_FILE"
echo -e "# Modelo: $cpu_model" >> "$OUTPUT_FILE"
echo -e "# Sockets: $num_sockets" >> "$OUTPUT_FILE"
echo -e "# Núcleos físicos por socket: $cores_per_socket" >> "$OUTPUT_FILE"
echo -e "# Total de núcleos físicos: $total_physical_cores" >> "$OUTPUT_FILE"
echo -e "# Total de núcleos lógicos: $logical_cores" >> "$OUTPUT_FILE"
echo -e "# Hilos por núcleo: $threads_per_core" >> "$OUTPUT_FILE"
echo -e "# Hyper-Threading/SMT: $ht_support" >> "$OUTPUT_FILE"
echo -e "" >> "$OUTPUT_FILE"

# 1. Detectar sensores de temperatura
report "\n${BLUE}=== SENSORES DE TEMPERATURA DETECTADOS ===${NC}"

# Array para almacenar sensores de temperatura encontrados
declare -a temp_sensors

# Buscar en /sys/class/hwmon
for hwmon in /sys/class/hwmon/hwmon*; do
    if [ -d "$hwmon" ]; then
        # Verificar si hay información del nombre
        if [ -f "$hwmon/name" ]; then
            hw_name=$(cat "$hwmon/name")
            
            # Buscar archivos temp*_input
            for temp_file in "$hwmon"/temp*_input; do
                if [ -f "$temp_file" ]; then
                    # Leer el valor y convertirlo a grados Celsius (dividir por 1000)
                    raw_value=$(cat "$temp_file" 2>/dev/null)
                    if is_numeric "$raw_value"; then
                        temp_value=$(echo "scale=1; $raw_value / 1000" | bc)
                        
                        # Intentar obtener la etiqueta
                        label_file="${temp_file/_input/_label}"
                        if [ -f "$label_file" ]; then
                            label=$(cat "$label_file" 2>/dev/null)
                        else
                            # Si no hay etiqueta, usar el número de índice extraído del nombre de archivo
                            temp_index=$(echo "$temp_file" | grep -o "temp[0-9]*" | sed 's/temp//')
                            if [ "$temp_index" = "1" ]; then
                                label="CPU Package"
                            else
                                label="Core $((temp_index - 2))"
                            fi
                        fi
                        
                        # Almacenar el sensor encontrado
                        temp_sensors+=("$temp_file|$label|$temp_value")
                        report "Sensor: ${YELLOW}$temp_file${NC} ($label) - Valor actual: ${GREEN}${temp_value}°C${NC}"
                    fi
                fi
            done
        fi
    fi
done

# Buscar en /sys/class/thermal
for thermal_zone in /sys/class/thermal/thermal_zone*; do
    if [ -d "$thermal_zone" ]; then
        # Verificar si hay un archivo de temperatura
        if [ -f "$thermal_zone/temp" ]; then
            # Leer el valor y convertirlo a grados Celsius (dividir por 1000)
            raw_value=$(cat "$thermal_zone/temp" 2>/dev/null)
            if is_numeric "$raw_value"; then
                temp_value=$(echo "scale=1; $raw_value / 1000" | bc)
                
                # Intentar obtener el tipo
                if [ -f "$thermal_zone/type" ]; then
                    label=$(cat "$thermal_zone/type" 2>/dev/null)
                else
                    # Si no hay tipo, usar el número de zona termal
                    zone_num=$(echo "$thermal_zone" | grep -o "[0-9]*$")
                    label="Thermal Zone $zone_num"
                fi
                
                # Almacenar el sensor encontrado
                temp_sensors+=("$thermal_zone/temp|$label|$temp_value")
                report "Sensor: ${YELLOW}$thermal_zone/temp${NC} ($label) - Valor actual: ${GREEN}${temp_value}°C${NC}"
            fi
        fi
    fi
done

# Si no se encontraron sensores de temperatura
if [ ${#temp_sensors[@]} -eq 0 ]; then
    report "${RED}No se encontraron sensores de temperatura disponibles${NC}"
    echo "# No se encontraron sensores de temperatura válidos" >> "$OUTPUT_FILE"
else
    # Seleccionar el mejor sensor de temperatura (preferimos CPU Package o el primero en la lista)
    best_temp_sensor=""
    for sensor in "${temp_sensors[@]}"; do
        IFS='|' read -r path label value <<< "$sensor"
        if [[ "$label" == *"CPU Package"* ]] || [[ "$label" == *"Package"* ]]; then
            best_temp_sensor="$path"
            best_temp_label="$label"
            break
        fi
    done
    
    # Si no encontramos CPU Package, usar el primer sensor
    if [ -z "$best_temp_sensor" ] && [ ${#temp_sensors[@]} -gt 0 ]; then
        IFS='|' read -r best_temp_sensor best_temp_label _ <<< "${temp_sensors[0]}"
    fi
    
    # Guardar la configuración
    echo -e "# Sensor de temperatura principal (${best_temp_label})" >> "$OUTPUT_FILE"
    echo "core_temp=$best_temp_sensor" >> "$OUTPUT_FILE"
    report "\nSensor de temperatura ${GREEN}recomendado${NC}: $best_temp_sensor ($best_temp_label)"
fi

report ""

# 2. Detectar sensores de energía (RAPL)
report "${BLUE}=== SENSORES DE ENERGÍA DETECTADOS (RAPL) ===${NC}"

# Array para almacenar sensores de energía encontrados
declare -a energy_sensors

# Función para calcular potencia en watts a partir de dos lecturas de energía
calculate_power() {
    local file=$1
    local first=$(cat "$file" 2>/dev/null)
    
    # Esperar un breve período para la segunda lectura
    sleep 0.2
    
    local second=$(cat "$file" 2>/dev/null)
    
    # Si cualquiera de las lecturas falló, retornar "N/A"
    if ! is_numeric "$first" || ! is_numeric "$second"; then
        echo "N/A"
        return
    fi
    
    # Calcular la diferencia (considerando envolvimiento)
    local diff
    if [ "$second" -lt "$first" ]; then
        # Desbordamiento (32 bits): 2^32 = 4294967296
        diff=$((4294967296 + second - first))
    else
        diff=$((second - first))
    fi
    
    # Calcular potencia: diferencia en microjoules / tiempo en segundos
    # El resultado es en watts (microjoules/segundo dividido por 1000000)
    echo "scale=2; $diff / 0.2 / 1000000" | bc
}

# Verificar si el directorio intel-rapl existe
if [ -d "/sys/class/powercap/intel-rapl" ]; then
    # Buscar sensores de energía RAPL para el paquete principal (CPU)
    for rapl_dir in /sys/class/powercap/intel-rapl/intel-rapl:*; do
        if [ -d "$rapl_dir" ]; then
            # Verificar si existe el archivo energy_uj
            if [ -f "$rapl_dir/energy_uj" ]; then
                # Intentar leer el valor y calcular potencia
                energy_file="$rapl_dir/energy_uj"
                power_watts=$(calculate_power "$energy_file")
                
                # Obtener el nombre del dominio
                if [ -f "$rapl_dir/name" ]; then
                    domain_name=$(cat "$rapl_dir/name" 2>/dev/null)
                else
                    domain_name="package-$(echo "$rapl_dir" | grep -o "[0-9]*$")"
                fi
                
                # Almacenar el sensor encontrado
                energy_sensors+=("$energy_file|$domain_name|$power_watts")
                report "RAPL ${domain_name}: ${YELLOW}$energy_file${NC} - Valor actual: ${GREEN}${power_watts} W${NC}"
                
                # Buscar subdominios (core, uncore, dram)
                for subdir in "$rapl_dir"/intel-rapl:*:*; do
                    if [ -d "$subdir" ] && [ -f "$subdir/energy_uj" ]; then
                        # Intentar leer el valor y calcular potencia
                        energy_file="$subdir/energy_uj"
                        power_watts=$(calculate_power "$energy_file")
                        
                        # Obtener el nombre del subdominio
                        if [ -f "$subdir/name" ]; then
                            subdomain_name=$(cat "$subdir/name" 2>/dev/null)
                        else
                            subdomain_name=$(basename "$subdir")
                        fi
                        
                        # Almacenar el sensor encontrado
                        energy_sensors+=("$energy_file|$subdomain_name|$power_watts")
                        report "RAPL ${subdomain_name}: ${YELLOW}$energy_file${NC} - Valor actual: ${GREEN}${power_watts} W${NC}"
                    fi
                done
            fi
        fi
    done
else
    # Verificar si existe la ruta alternativa
    if [ -d "/sys/class/powercap/intel-rapl:0" ]; then
        for rapl_dir in /sys/class/powercap/intel-rapl:*; do
            if [ -d "$rapl_dir" ] && [ -f "$rapl_dir/energy_uj" ]; then
                # Intentar leer el valor y calcular potencia
                energy_file="$rapl_dir/energy_uj"
                power_watts=$(calculate_power "$energy_file")
                
                # Obtener el nombre del dominio
                if [ -f "$rapl_dir/name" ]; then
                    domain_name=$(cat "$rapl_dir/name" 2>/dev/null)
                else
                    domain_name="package-$(echo "$rapl_dir" | grep -o "[0-9]*$")"
                fi
                
                # Almacenar el sensor encontrado
                energy_sensors+=("$energy_file|$domain_name|$power_watts")
                report "RAPL ${domain_name}: ${YELLOW}$energy_file${NC} - Valor actual: ${GREEN}${power_watts} W${NC}"
                
                # Buscar subdominios con un patrón alternativo
                for subdir in "$rapl_dir":*; do
                    if [ -d "$subdir" ] && [ -f "$subdir/energy_uj" ]; then
                        # Intentar leer el valor y calcular potencia
                        energy_file="$subdir/energy_uj"
                        power_watts=$(calculate_power "$energy_file")
                        
                        # Obtener el nombre del subdominio
                        if [ -f "$subdir/name" ]; then
                            subdomain_name=$(cat "$subdir/name" 2>/dev/null)
                        else
                            subdomain_name=$(basename "$subdir")
                        fi
                        
                        # Almacenar el sensor encontrado
                        energy_sensors+=("$energy_file|$subdomain_name|$power_watts")
                        report "RAPL ${subdomain_name}: ${YELLOW}$energy_file${NC} - Valor actual: ${GREEN}${power_watts} W${NC}"
                    fi
                done
            fi
        done
    else
        report "${RED}No se encontraron interfaces RAPL para monitoreo de energía${NC}"
        report "${YELLOW}Es posible que necesite cargar el módulo del kernel:${NC} sudo modprobe intel_rapl_common"
    fi
fi

# Si no se encontraron sensores de energía
if [ ${#energy_sensors[@]} -eq 0 ]; then
    report "${RED}No se encontraron sensores de energía disponibles${NC}"
    echo "# No se encontraron sensores de energía válidos" >> "$OUTPUT_FILE"
else
    # Seleccionar el mejor sensor de energía (preferimos 'core' o el primero en la lista)
    best_energy_sensor=""
    for sensor in "${energy_sensors[@]}"; do
        IFS='|' read -r path label value <<< "$sensor"
        if [[ "$label" == *"core"* ]]; then
            best_energy_sensor="$path"
            best_energy_label="$label"
            break
        fi
    done
    
    # Si no encontramos 'core', usar el primer sensor
    if [ -z "$best_energy_sensor" ] && [ ${#energy_sensors[@]} -gt 0 ]; then
        IFS='|' read -r best_energy_sensor best_energy_label _ <<< "${energy_sensors[0]}"
    fi
    
    # Guardar la configuración
    echo -e "# Sensor de energía - ${best_energy_label} (para monitorear consumo de núcleos de CPU)" >> "$OUTPUT_FILE"
    echo -e "# Importante: Este sensor proporciona datos de energía acumulada (joules), no potencia instantánea (watts)" >> "$OUTPUT_FILE"
    echo -e "# El programa monitor calculará la potencia basada en la diferencia de energía entre mediciones" >> "$OUTPUT_FILE"
    echo "core_power=$best_energy_sensor" >> "$OUTPUT_FILE"
    report "\nSensor de energía ${GREEN}recomendado${NC}: $best_energy_sensor ($best_energy_label)"
fi

report ""

# 3. Detectar información de frecuencia de CPU y gobernadores
report "${BLUE}=== FRECUENCIA DE CPU Y GOBERNADORES DETECTADOS ===${NC}"

# Array para almacenar archivos de frecuencia encontrados
declare -a freq_files
declare -a all_core_freqs

# Detectar número de CPUs en el sistema
NUM_CPUS=$logical_cores
report "Sistema con ${YELLOW}${NUM_CPUS}${NC} núcleos de CPU detectados"

# Buscar información de frecuencia para cada núcleo
report "\nFrecuencias individuales por núcleo:"
total_freq=0
available_cores=0

for cpu_num in $(seq 0 $((NUM_CPUS-1))); do
    cpu_dir="/sys/devices/system/cpu/cpu${cpu_num}/cpufreq"
    
    if [ -d "$cpu_dir" ]; then
        # Comprobar archivos de frecuencia comunes
        for freq_file in "scaling_cur_freq" "cpuinfo_cur_freq"; do
            file_path="${cpu_dir}/${freq_file}"
            if [ -f "$file_path" ]; then
                # Intentar leer el valor
                freq_value=$(cat "$file_path" 2>/dev/null)
                if is_numeric "$freq_value"; then
                    # Convertir de kHz a MHz
                    freq_mhz=$(echo "scale=2; $freq_value / 1000" | bc)
                    
                    # Almacenar la frecuencia para cálculo de promedio
                    total_freq=$(echo "$total_freq + $freq_mhz" | bc)
                    available_cores=$((available_cores + 1))
                    
                    # Almacenar el archivo encontrado para CPU0 (referencia principal)
                    if [ "$cpu_num" -eq 0 ]; then
                        freq_files+=("$file_path|$freq_file|$freq_mhz")
                    fi
                    
                    # Almacenar todas las rutas de frecuencia por núcleo
                    all_core_freqs+=("$file_path|CPU$cpu_num|$freq_mhz")
                    
                    # Obtener el gobernador para este núcleo
                    governor=""
                    if [ -f "${cpu_dir}/scaling_governor" ]; then
                        governor=$(cat "${cpu_dir}/scaling_governor" 2>/dev/null)
                        governor=" Gob:${governor}"
                    fi
                    
                    report "  CPU$cpu_num: ${YELLOW}$file_path${NC} - Valor actual: ${GREEN}${freq_mhz} MHz${NC}${governor}"
                    # Solo necesitamos un archivo de frecuencia por CPU
                    break
                fi
            fi
        done
    fi
done

# Calcular frecuencia media si hay núcleos disponibles
if [ $available_cores -gt 0 ]; then
    avg_freq=$(echo "scale=2; $total_freq / $available_cores" | bc)
    report "\nFrecuencia media de todos los núcleos: ${GREEN}${avg_freq} MHz${NC}"
fi

# Información sobre gobernadores de CPU
report "\n${BLUE}=== GOBERNADORES DE FRECUENCIA ===${NC}"

# Variables para almacenar información de gobernadores
current_governor=""
available_governors=""
cpu_vendor=""
energy_perf_prefs=""
available_prefs=""

if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
    current_governor=$(cat "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" 2>/dev/null)
    report "${GREEN}Gobernador de frecuencia actual:${NC} ${BOLD}${current_governor}${NC}"
    
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors" ]; then
        available_governors=$(cat "/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors" 2>/dev/null)
        report "${GREEN}Gobernadores disponibles:${NC} ${available_governors}"
        
        # Añadir información de gobernadores a la configuración recomendada
        echo -e "# Configuración de gobernadores de frecuencia" >> "$OUTPUT_FILE"
        echo -e "# Gobernador actual: $current_governor" >> "$OUTPUT_FILE"
        echo -e "# Gobernadores disponibles: $available_governors" >> "$OUTPUT_FILE"
        echo -e "" >> "$OUTPUT_FILE"
        
        # Sugerencias basadas en gobernador actual
        report "\n${YELLOW}Sugerencias para gobernadores:${NC}"
        if [ "$current_governor" = "performance" ]; then
            report "  • Usando el gobernador '${BOLD}performance${NC}': Máximo rendimiento, óptimo para pruebas de carga."
            report "  • Este gobernador mantiene la frecuencia máxima constantemente."
        elif [ "$current_governor" = "powersave" ]; then
            report "  • Usando el gobernador '${BOLD}powersave${NC}': Bajo rendimiento, ahorra energía pero puede afectar las pruebas."
            report "  • Para pruebas de rendimiento considere cambiar a '${BOLD}performance${NC}' usando:"
            report "    ${YELLOW}echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor${NC}"
        elif [ "$current_governor" = "ondemand" ] || [ "$current_governor" = "schedutil" ]; then
            report "  • Usando el gobernador '${BOLD}$current_governor${NC}': Ajuste dinámico, puede causar variabilidad en las pruebas."
            report "  • Para resultados más consistentes considere usar '${BOLD}performance${NC}' temporalmente:"
            report "    ${YELLOW}echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor${NC}"
        fi
    fi
    
    # Obtener información del fabricante de CPU para recomendaciones específicas
    if grep -q "Intel" /proc/cpuinfo; then
        cpu_vendor="Intel"
    elif grep -q "AMD" /proc/cpuinfo; then
        cpu_vendor="AMD"
    else
        cpu_vendor="Genérico"
    fi
    
    # Mostrar el rango de frecuencia
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq" ] && [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq" ]; then
        min_freq=$(cat "/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq" 2>/dev/null)
        max_freq=$(cat "/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq" 2>/dev/null)
        
        if is_numeric "$min_freq" && is_numeric "$max_freq"; then
            min_freq_mhz=$(echo "scale=0; $min_freq / 1000" | bc)
            max_freq_mhz=$(echo "scale=0; $max_freq / 1000" | bc)
            report "\n${GREEN}Rango de frecuencia:${NC} ${min_freq_mhz} MHz - ${max_freq_mhz} MHz"
            
            # Añadir información de rango a la configuración
            echo -e "# Rango de frecuencia: ${min_freq_mhz} MHz - ${max_freq_mhz} MHz" >> "$OUTPUT_FILE"
        fi
    fi
else
    report "${YELLOW}No se encontró interfaz cpufreq para monitoreo de frecuencia${NC}"
    
    # Intentar obtener la frecuencia desde /proc/cpuinfo
    if grep -q "cpu MHz" /proc/cpuinfo; then
        avg_mhz=0
        count=0
        while read -r line; do
            mhz_value=$(echo "$line" | awk -F': ' '{print $2}')
            avg_mhz=$(echo "$avg_mhz + $mhz_value" | bc)
            count=$((count + 1))
        done < <(grep "cpu MHz" /proc/cpuinfo)
        
        if [ $count -gt 0 ]; then
            avg_mhz=$(echo "scale=2; $avg_mhz / $count" | bc)
            report "Frecuencia media desde /proc/cpuinfo: ${GREEN}${avg_mhz} MHz${NC}"
        fi
        
        report "${YELLOW}Nota: Se usará el método alternativo (desde /proc/cpuinfo) para monitorear la frecuencia${NC}"
    else
        report "${RED}No se pudo detectar la frecuencia de la CPU${NC}"
    fi
fi

# Información de modos de energía del CPU (si está disponible)
if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference" ]; then
    energy_perf=$(cat "/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference" 2>/dev/null)
    report "\n${GREEN}Perfil de energía/rendimiento:${NC} ${energy_perf}"
    energy_perf_prefs="$energy_perf"
    
    # Añadir información de perfil de energía a la configuración
    echo -e "# Perfil de energía/rendimiento: $energy_perf" >> "$OUTPUT_FILE"
    
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_available_preferences" ]; then
        available_prefs=$(cat "/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_available_preferences" 2>/dev/null)
        report "${GREEN}Perfiles disponibles:${NC} ${available_prefs}"
        echo -e "# Perfiles disponibles: $available_prefs" >> "$OUTPUT_FILE"
    fi
fi

# Añadir perfiles de configuración recomendados
report "\n${BLUE}=== PERFILES DE CONFIGURACIÓN RECOMENDADOS ===${NC}"
report "Basado en el hardware detectado, se recomiendan los siguientes perfiles:"

# Crear un directorio de perfiles de configuración si no existe
PROFILES_DIR="profiles"
mkdir -p "$PROFILES_DIR"

# 1. Perfil de Alto Rendimiento
report "\n${YELLOW}1. Perfil de Alto Rendimiento${NC} (máxima velocidad, ideal para benchmarking)"
HIGH_PERF_CONFIG="$PROFILES_DIR/config_high_performance.txt"

cat > "$HIGH_PERF_CONFIG" <<EOF
# Configuración optimizada para MÁXIMO RENDIMIENTO
# Generado: $(date "+%Y-%m-%d")
# ----------------------------------------------------
# Este perfil prioriza el rendimiento sobre el consumo energético
# Ideal para: benchmarks, pruebas de carga, procesamiento intensivo
EOF

# Copiar configuraciones básicas desde el archivo principal
cat "$OUTPUT_FILE" | grep -v "^#" | grep "=" >> "$HIGH_PERF_CONFIG"

# Añadir configuraciones específicas para rendimiento
cat >> "$HIGH_PERF_CONFIG" <<EOF

# Configuración específica para alto rendimiento
# ----------------------------------------------------
# Gobernador recomendado: performance (mantiene la CPU a máxima frecuencia)
governor_profile=performance
EOF

# Añadir recomendación de perfil energético si está disponible
if [ -n "$available_prefs" ]; then
    if [[ "$available_prefs" == *"performance"* ]]; then
        echo "energy_performance_preference=performance" >> "$HIGH_PERF_CONFIG"
    fi
fi

# Añadir ajustes específicos según el fabricante
if [ "$cpu_vendor" = "Intel" ]; then
    cat >> "$HIGH_PERF_CONFIG" <<EOF
# Ajustes específicos para procesadores Intel
# ----------------------------------------------------
# Para CPUs Intel modernos, deshabilitar el límite de potencia puede mejorar el rendimiento
# ADVERTENCIA: Esto puede aumentar la temperatura y consumo energético
# Descomente si desea aumentar los límites de potencia (requiere privilegios root):
# intel_pstate_limits=off
EOF
elif [ "$cpu_vendor" = "AMD" ]; then
    cat >> "$HIGH_PERF_CONFIG" <<EOF
# Ajustes específicos para procesadores AMD
# ----------------------------------------------------
# Para CPUs AMD Ryzen, el gobernador "performance" suele ser el más recomendado
# En algunos modelos, puede probar el perfil "boost" si está disponible
EOF
fi

report "Configuración guardada en: ${GREEN}$HIGH_PERF_CONFIG${NC}"
report "Para aplicar este perfil: ${YELLOW}sudo ./set_profile.sh --profile high_performance${NC}"


# 2. Perfil Balanceado
report "\n${YELLOW}2. Perfil Balanceado${NC} (equilibrio entre rendimiento y consumo)"
BALANCED_CONFIG="$PROFILES_DIR/config_balanced.txt"

cat > "$BALANCED_CONFIG" <<EOF
# Configuración BALANCEADA entre rendimiento y consumo energético
# Generado: $(date "+%Y-%m-%d")
# ----------------------------------------------------
# Este perfil busca un equilibrio entre rendimiento y eficiencia energética
# Ideal para: cargas de trabajo cotidianas, servidores con carga moderada
EOF

# Copiar configuraciones básicas desde el archivo principal
cat "$OUTPUT_FILE" | grep -v "^#" | grep "=" >> "$BALANCED_CONFIG"

# Añadir configuraciones específicas para perfil balanceado
cat >> "$BALANCED_CONFIG" <<EOF

# Configuración específica para perfil balanceado
# ----------------------------------------------------
EOF

# Determinar el mejor gobernador para el perfil balanceado
if [[ "$available_governors" == *"schedutil"* ]]; then
    echo "# Gobernador recomendado: schedutil (ajuste dinámico basado en carga con bajo overhead)" >> "$BALANCED_CONFIG"
    echo "governor_profile=schedutil" >> "$BALANCED_CONFIG"
elif [[ "$available_governors" == *"ondemand"* ]]; then
    echo "# Gobernador recomendado: ondemand (ajuste dinámico basado en carga)" >> "$BALANCED_CONFIG"
    echo "governor_profile=ondemand" >> "$BALANCED_CONFIG"
else
    echo "# Gobernador recomendado: el más adecuado disponible en su sistema" >> "$BALANCED_CONFIG"
fi

# Añadir recomendación de perfil energético si está disponible
if [ -n "$available_prefs" ]; then
    if [[ "$available_prefs" == *"balance_performance"* ]]; then
        echo "energy_performance_preference=balance_performance" >> "$BALANCED_CONFIG"
    elif [[ "$available_prefs" == *"balanced"* ]]; then
        echo "energy_performance_preference=balanced" >> "$BALANCED_CONFIG"
    fi
fi

# Añadir ajustes específicos según el fabricante
if [ "$cpu_vendor" = "Intel" ]; then
    cat >> "$BALANCED_CONFIG" <<EOF
# Ajustes específicos para procesadores Intel
# ----------------------------------------------------
# Los procesadores Intel modernos funcionan bien con el gobernador "schedutil"
# y el perfil de energía "balance_performance"
EOF
elif [ "$cpu_vendor" = "AMD" ]; then
    cat >> "$BALANCED_CONFIG" <<EOF
# Ajustes específicos para procesadores AMD
# ----------------------------------------------------
# Los procesadores AMD Ryzen funcionan bien con el gobernador "schedutil"
# o alternativamente "ondemand" para un balance óptimo
EOF
fi

report "Configuración guardada en: ${GREEN}$BALANCED_CONFIG${NC}"
report "Para aplicar este perfil: ${YELLOW}sudo ./set_profile.sh --profile balanced${NC}"


# 3. Perfil de Bajo Consumo
report "\n${YELLOW}3. Perfil de Bajo Consumo${NC} (ahorro energético, rendimiento reducido)"
POWER_SAVE_CONFIG="$PROFILES_DIR/config_power_save.txt"

cat > "$POWER_SAVE_CONFIG" <<EOF
# Configuración optimizada para AHORRO DE ENERGÍA
# Generado: $(date "+%Y-%m-%d")
# ----------------------------------------------------
# Este perfil prioriza la eficiencia energética sobre el rendimiento
# Ideal para: servidores con baja carga, entornos donde la temperatura es crítica
EOF

# Copiar configuraciones básicas desde el archivo principal
cat "$OUTPUT_FILE" | grep -v "^#" | grep "=" >> "$POWER_SAVE_CONFIG"

# Añadir configuraciones específicas para bajo consumo
cat >> "$POWER_SAVE_CONFIG" <<EOF

# Configuración específica para ahorro de energía
# ----------------------------------------------------
# Gobernador recomendado: powersave (reducción de frecuencia para minimizar consumo)
governor_profile=powersave
EOF

# Añadir recomendación de perfil energético si está disponible
if [ -n "$available_prefs" ]; then
    if [[ "$available_prefs" == *"power"* ]]; then
        echo "energy_performance_preference=power" >> "$POWER_SAVE_CONFIG"
    elif [[ "$available_prefs" == *"balance_power"* ]]; then
        echo "energy_performance_preference=balance_power" >> "$POWER_SAVE_CONFIG"
    fi
fi

report "Configuración guardada en: ${GREEN}$POWER_SAVE_CONFIG${NC}"
report "Para aplicar este perfil: ${YELLOW}sudo ./set_profile.sh --profile power_save${NC}"

# Generar el script para aplicar perfiles
SET_PROFILE_SCRIPT="set_profile.sh"

cat > "$SET_PROFILE_SCRIPT" <<'EOF'
#!/bin/bash

# Script para aplicar perfiles de rendimiento al sistema
# Autor: Server Load Testing Team

# Colores para salida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Verificar si se ejecuta como root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: Este script debe ejecutarse como root.${NC}"
    echo -e "Intente: ${YELLOW}sudo $0 $*${NC}"
    exit 1
fi

# Mostrar ayuda
show_help() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  -p, --profile PERFIL        Aplica un perfil predefinido (high_performance, balanced, power_save)"
    echo "  -g, --governor GOBERNADOR   Establece un gobernador específico para todas las CPUs"
    echo "  -e, --epp PERFIL           Establece un perfil energy_performance_preference específico"
    echo "  -l, --list                  Lista los perfiles y configuraciones disponibles"
    echo "  -h, --help                  Muestra esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 --profile high_performance    # Aplica el perfil de alto rendimiento"
    echo "  $0 --governor performance        # Establece el gobernador 'performance' en todas las CPUs"
    echo "  $0 --epp balance_performance     # Establece el perfil energy_performance_preference"
    echo ""
}

# Funciones para aplicar configuraciones
set_cpu_governor() {
    local governor=$1
    echo -e "\n${BLUE}=== Configurando gobernador de CPU ===${NC}"
    
    # Obtener número de CPUs
    num_cpus=$(grep -c ^processor /proc/cpuinfo)
    echo -e "Sistema con ${YELLOW}${num_cpus}${NC} núcleos de CPU detectados"
    
    for cpu_num in $(seq 0 $((num_cpus-1))); do
        gov_file="/sys/devices/system/cpu/cpu${cpu_num}/cpufreq/scaling_governor"
        if [ -f "$gov_file" ]; then
            echo -e "Configurando CPU$cpu_num a gobernador: ${GREEN}${governor}${NC}"
            echo "$governor" > "$gov_file"
        fi
    done
    
    # Verificar que se aplicó correctamente
    sleep 0.5
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
        current=$(cat "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor")
        if [ "$current" = "$governor" ]; then
            echo -e "\n${GREEN}✓ Gobernador '$governor' aplicado correctamente${NC}"
        else
            echo -e "\n${RED}✗ Error al aplicar el gobernador. Actual: '$current'${NC}"
        fi
    fi
}

set_energy_perf_preference() {
    local preference=$1
    local success=0
    local total=0
    
    echo -e "\n${BLUE}=== Configurando perfil energía/rendimiento ===${NC}"
    
    # Obtener número de CPUs
    num_cpus=$(grep -c ^processor /proc/cpuinfo)
    
    for cpu_num in $(seq 0 $((num_cpus-1))); do
        epp_file="/sys/devices/system/cpu/cpu${cpu_num}/cpufreq/energy_performance_preference"
        if [ -f "$epp_file" ]; then
            echo -e "Configurando CPU$cpu_num a perfil: ${GREEN}${preference}${NC}"
            echo "$preference" > "$epp_file" 2>/dev/null
            
            # Verificar si se aplicó correctamente
            total=$((total + 1))
            current=$(cat "$epp_file" 2>/dev/null)
            if [ "$current" = "$preference" ]; then
                success=$((success + 1))
            fi
        fi
    done
    
    # Mostrar resultado
    if [ $total -eq 0 ]; then
        echo -e "\n${YELLOW}⚠ El sistema no soporta energy_performance_preference${NC}"
    elif [ $success -eq $total ]; then
        echo -e "\n${GREEN}✓ Perfil '$preference' aplicado correctamente a $success CPUs${NC}"
    else
        echo -e "\n${YELLOW}⚠ Perfil aplicado parcialmente: $success de $total CPUs${NC}"
    fi
}

apply_profile() {
    local profile=$1
    local config_file="profiles/config_${profile}.txt"
    
    # Verificar que el archivo de perfil existe
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Error: Perfil no encontrado: $config_file${NC}"
        echo -e "Perfiles disponibles:"
        list_profiles
        exit 1
    fi
    
    echo -e "${BLUE}=== Aplicando perfil: ${BOLD}${profile}${NC} ===${NC}"
    echo -e "Usando archivo de configuración: $config_file\n"
    
    # Extraer y aplicar gobernador si está especificado
    if grep -q "^governor_profile=" "$config_file"; then
        governor=$(grep "^governor_profile=" "$config_file" | cut -d'=' -f2)
        set_cpu_governor "$governor"
    fi
    
    # Extraer y aplicar energy_performance_preference si está especificado
    if grep -q "^energy_performance_preference=" "$config_file"; then
        epp=$(grep "^energy_performance_preference=" "$config_file" | cut -d'=' -f2)
        set_energy_perf_preference "$epp"
    fi
    
    # Extraer y aplicar otras configuraciones específicas del perfil
    if grep -q "^intel_pstate_limits=" "$config_file"; then
        intel_limit=$(grep "^intel_pstate_limits=" "$config_file" | cut -d'=' -f2)
        if [ "$intel_limit" = "off" ]; then
            echo -e "\n${BLUE}=== Configurando límites de potencia Intel ===${NC}"
            echo -e "${YELLOW}⚠ Advertencia: Desactivar límites de potencia puede aumentar temperatura y consumo${NC}"
            if [ -f "/sys/devices/system/cpu/intel_pstate/no_turbo" ]; then
                echo "0" > "/sys/devices/system/cpu/intel_pstate/no_turbo"
                echo -e "${GREEN}✓ Turbo Boost activado${NC}"
            fi
        fi
    fi
    
    echo -e "\n${GREEN}✓ Perfil '$profile' aplicado correctamente${NC}"
}

list_profiles() {
    echo -e "\n${BLUE}=== Perfiles disponibles ===${NC}"
    
    # Buscar archivos de perfil
    if [ -d "profiles" ]; then
        profiles=$(find "profiles" -name "config_*.txt" | sort)
        if [ -n "$profiles" ]; then
            for profile in $profiles; do
                profile_name=$(basename "$profile" | sed 's/config_\(.*\).txt/\1/')
                profile_desc=$(head -n 10 "$profile" | grep "^# Config" | head -n 1 | cut -d'#' -f2-)
                echo -e "${YELLOW}${profile_name}${NC} - ${profile_desc}"
            done
        else
            echo -e "${YELLOW}No se encontraron perfiles predefinidos${NC}"
        fi
    else
        echo -e "${YELLOW}No se encontró el directorio de perfiles${NC}"
    fi
    
    echo -e "\n${BLUE}=== Gobernadores disponibles ===${NC}"
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors" ]; then
        available=$(cat "/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors" 2>/dev/null)
        echo -e "${GREEN}$available${NC}"
    else
        echo -e "${YELLOW}No se pueden detectar los gobernadores disponibles${NC}"
    fi
    
    echo -e "\n${BLUE}=== Perfiles de energía disponibles ===${NC}"
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_available_preferences" ]; then
        available=$(cat "/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_available_preferences" 2>/dev/null)
        echo -e "${GREEN}$available${NC}"
    else
        echo -e "${YELLOW}Sistema no soporta energy_performance_preference${NC}"
    fi
}

# Procesar parámetros de línea de comandos
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

while [ $# -gt 0 ]; do
    case "$1" in
        -p|--profile)
            apply_profile "$2"
            shift 2
            ;;
        -g|--governor)
            set_cpu_governor "$2"
            shift 2
            ;;
        -e|--epp)
            set_energy_perf_preference "$2"
            shift 2
            ;;
        -l|--list)
            list_profiles
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Opción desconocida: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

exit 0
EOF

# Hacer ejecutable el script
chmod +x "$SET_PROFILE_SCRIPT"

report "\n${BOLD}=== SCRIPT DE APLICACIÓN DE PERFILES CREADO ===${NC}"
report "Se ha generado el script ${GREEN}$SET_PROFILE_SCRIPT${NC} para facilitar la aplicación de perfiles"
report "Ejemplos de uso:"
report "  ${YELLOW}sudo ./$SET_PROFILE_SCRIPT --profile high_performance${NC}   # Para máximo rendimiento"
report "  ${YELLOW}sudo ./$SET_PROFILE_SCRIPT --profile balanced${NC}          # Para equilibrio rendimiento/energía"
report "  ${YELLOW}sudo ./$SET_PROFILE_SCRIPT --profile power_save${NC}        # Para ahorro energético"
report "  ${YELLOW}sudo ./$SET_PROFILE_SCRIPT --list${NC}                      # Para ver todos los perfiles disponibles"

# Al final del script, asegurar que los nombres de los archivos se muestren correctamente
report "\n${BOLD}=== DETECCIÓN DE SENSORES COMPLETADA ===${NC}"
report "Archivo de configuración recomendado generado: ${GREEN}$OUTPUT_FILE${NC}"
report "Informe detallado de sensores guardado en: ${GREEN}$REPORT_FILE${NC}"
report "Informe detallado de CPU guardado en: ${GREEN}$REPORT_CPU_FILE${NC}"
report "Reporte completo (idéntico a la salida por pantalla) guardado en: ${GREEN}$REPORT_FULL_FILE${NC}"
report "\nPara usar esta configuración:"
report "${YELLOW}cp $OUTPUT_FILE config.txt${NC}"

# Al final del script, eliminar cualquier línea adicional al final y asegurar que termine con una nueva línea
for file in "$REPORT_FILE" "$REPORT_CPU_FILE" "$REPORT_FULL_FILE"; do
    if [ -f "$file" ]; then
        # Eliminar espacios en blanco al final del archivo (si los hay)
        sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$file"
    fi
done