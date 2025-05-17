# Paths comunes para monitoreo de sensores en Linux

#    Temperatura:
t1="/sys/class/thermal/thermal_zone*/temp"  # Miligrados Celsius (dividir por 1000 para obtener °C).
t2="/sys/class/hwmon/hwmon*/temp*_input"    # Miligrados Celsius

#    Frecuencia de CPU:
f1="/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq"  # kHz
f2="/sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq"  # kHz
f3="/sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq"  # kHz
f4="/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"  # texto

#    Energía (consumo energético):
# con sudo
e1="/sys/class/powercap/intel-rapl/intel-rapl:*/energy_uj"   # Microjulios (µJ)
e2="/sys/class/powercap/intel-rapl/intel-rapl:0/intel-rapl:0:0/energy_uj" 
e3="/sys/class/power_supply/BAT*/energy_now"    # Microvatios (µW) o microjulios (µJ), dependiendo del archivo
e4="/sys/class/power_supply/BAT*/power_now"     # Microvatios (µW) o microjulios (µJ), dependiendo del archivo

#    Información de CPU:
c1="/proc/cpuinfo"  # texto
c2="/proc/stat"     # texto