#!/bin/bash

sudo bash scripts/detect_sensors.sh

python3 scripts/env.detect.py

sudo rm sensors_report.txt report_cpu.txt report_full.txt set_profile.sh config.txt.recommended

sudo rm -rf profiles/ 