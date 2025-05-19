# server-inspector
server-inspector is a lightweight system profiling tool designed to collect and export detailed hardware and system information from Linux servers. It generates structured JSON output suitable for infrastructure audits, performance analysis, and inventory management.

---

## Instrucciones de uso

1. Clona el repositorio y accede a la carpeta del proyecto:
   ```bash
   git clone danunziata/server-inspector
   cd server-inspector
   ```
2. Da permisos de ejecución a los scripts:
   ```bash
   chmod +x generar.sh verificar_dependencias.sh descubrir_paths.sh scripts/*.sh
   ```

3. Ejecuta el script para verificar dependencias:
   ```bash
   ./verificar_dependencias.sh
   ```
   > **Recomendación:** Para obtener información completa, ejecuta con permisos de superusuario:
   > ```bash
   > sudo ./verificar_dependencias.sh
   > ```

4. Ejecuta el script principal:
   ```bash
   ./generar.sh
   ```
   > **Recomendación:** Para obtener información completa, ejecuta con permisos de superusuario:
   > ```bash
   > sudo ./generar.sh
   > ```

5. Ejecuta el script para detectar los paths de los sensores:
   ```bash
   ./descubrir_paths.sh
   ```
   > **Recomendación:** Para obtener información completa, ejecuta con permisos de superusuario:
   > ```bash
   > sudo ./descubrir_paths.sh
   > ```

## Herramientas necesarias

- bash (intérprete de comandos)
- python3
- lsb-release
- util-linux (lsblk, df, etc.)
- hdparm
- smartmontools (smartctl)
- coreutils
- lm-sensors (sensors, sensors-detect)
- tuned
- systemd (hostnamectl)
- lshw
- inxi (opcional)
- dmidecode

Puedes instalar todas las dependencias principales con:
```bash
sudo apt-get install lsb-release util-linux hdparm smartmontools coreutils lm-sensors tuned systemd lshw inxi dmidecode
```

## Recomendaciones sobre permisos y entorno

- Para obtener información completa de hardware y sensores, ejecuta los scripts con permisos de superusuario (`sudo`).
- Si ejecutas los scripts sin sudo, algunos datos avanzados (como información de módulos de RAM, discos o sensores) pueden no estar disponibles.
- El sistema está diseñado para funcionar en distribuciones Linux basadas en Debian/Ubuntu. Puede requerir ajustes menores en otras distribuciones.
- Los resultados se almacenan en la carpeta `carac_server` en formato JSON, listos para ser utilizados en auditorías o inventarios.
