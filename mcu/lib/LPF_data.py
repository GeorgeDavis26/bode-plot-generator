# Python
import numpy as np
import csv

# generate data
f = np.logspace(np.log10(100), np.log10(100000), 100)  # Hz
w = 2 * np.pi * f
fc = 1000.0  # cutoff Hz
w0 = 2 * np.pi * fc
Q = 0.707

H = (w0**2) / (-w**2 + 1j * (w * w0 / Q) + w0**2)
gain_db = 20 * np.log10(np.abs(H))
phase_deg = np.angle(H, deg=True)

# write CSV
with open('bode.csv', 'w', newline='') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['frequency_Hz', 'gain_dB', 'phase_deg'])
    for fi, gi, pi in zip(f, gain_db, phase_deg):
        writer.writerow([f"{fi:.6f}", f"{gi:.6f}", f"{pi:.6f}"])

print("Wrote bode.csv (100 points) in current directory.")