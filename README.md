# Capacitor Selection and Reliability Optimization System (CSROS)

Research prototype for capacitor screening in a 24 V to 12 V buck converter.

## Contents
- `capacitor_optimizer_v4.m`: MATLAB screening and scoring script
- `report.pdf`: technical report
- `report.docx`: editable report
- `figures/`: block diagrams and illustrative response plots

## Baseline
Vin=24 V, Vout reference=12 V, L=1 mH, fs=50 kHz, Rload=3.75 ohm.

## Limitations
Candidate data are not uniformly verified. Keep missing values as NaN. Ratings must be checked against exact datasheets and matching frequency/temperature conditions. Illustrative plots are not raw Simulink exports. No final winner is declared by the current dataset.
