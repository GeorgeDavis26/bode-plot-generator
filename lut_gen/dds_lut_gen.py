'''
authors: George Davis and Matthew Molinar
emails: gdavis@hmc.edu and mmolinar@hmc.edu
date created: 11/11/2025

dds_lut_gen.py
--------------------------------------------

Makes a quarter wave sine LUT for an 8-bit DAC.

This script generates an 8-bit quarter sine wave LUT with 64 entries, 
where as a full sine wave would have 256 entries.

Output: one 8-bit hex word per line, saved to 'sine_quarter_8.hex'.
'''

import math
from pathlib import Path

# Parameters
LUT_SIZE = 256
OUTPUT_FILENAME = "sine_quarter_8.hex"

def unsigned_from_float(x: float):
    """
    Convert a float in the range [0.0, 1.0] to an 8-bit unsigned int (0-255).
    """
    # Clamp to valid range
    x = max(min(x, 1.0), 0.0)
    # Scale to 8-bits and round to the nearest int
    return int(round(x * (2**8 - 1)))

def gen_quarter_table(full_lut_size: int):
    """
    Generates a quarter-wave sine table of 
    8-bit hex values for angles from 0 to pi/2.
    """
    quarter_lut_size = full_lut_size // 4
    for k in range(quarter_lut_size):

        # Calculate angle
        theta = (math.pi / 2.0) * k / quarter_lut_size
        s = math.sin(theta)

        # Convert to an 8-bit int and format as a 2-digit hex string
        yield f"{unsigned_from_float(s):02x}"

def main():
    """
    Main function to generate the LUT and write it to a file.
    """
 
    # Generate the LUT values
    lines = list(gen_quarter_table(LUT_SIZE))

    # Write the values to the output file
    outfile_path = Path(OUTPUT_FILENAME)
    with outfile_path.open("w", encoding="utf-8") as f:
        for line in lines:
            f.write(line + "\n")

    print(f"Wrote {len(lines)} lines to {outfile_path}")

if __name__ == "__main__":
    main()