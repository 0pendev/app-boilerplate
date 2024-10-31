#!/usr/bin/env python3
"""
Quick hack around the ledgerblue.loadApp module.
The ledger-secure-sdk evals the values of dataSize and installParamSize
from the memory mapping of the elf app. Make allows to mix build operation and configuration operations.
Using a cmake or meson script makes it impossible to reproduce te behavior (command parameters must be known at config time).

This mapping can only be known at build time thus it would make sense for the module to directly use the map file.
"""
import re
import sys
import subprocess
from pathlib import Path
from typing import List

def parse_hex_offset(map_file:str, symbol_name:str) -> int:
    """Extracts hexadecimal offset of a given symbol from the map file."""
    with open(map_file, "r") as f:
        for line in f:
            if symbol_name in line:
                # Extract the hex value from the line
                match = re.search(r'([0-9A-Fa-f]+)', line)
                if match:
                    return int(match.group(1), 16)
                else:
                    print(f'No match on line {line}')
    raise ValueError(f"Symbol '{symbol_name}' not found in {map_file}")

def main():
    # Check arguments
    if len(sys.argv) < 2:
        print("Usage: python parse_map.py <path_to_app_map>")
        sys.exit(1)

    # Get the path to the map file
    map_file = Path(sys.argv[1])
    if not map_file.is_file():
        print(f"Error: Map file '{map_file}' not found.")
        sys.exit(1)

    # Symbols to search in the map file
    symbols = dict()

    # Parse each symbol's offset
    try:
        for symbol in ["_envram_data", "_nvram_data", "_einstall_parameters", "_install_parameters"]:
            symbols[symbol] = parse_hex_offset(map_file, symbol)
        # Calculate data sizes
        data_size = symbols["_envram_data"] - symbols["_nvram_data"]
        installparams_size = symbols["_einstall_parameters"] - symbols["_install_parameters"]
        # Print results in CMake-friendly format
        args = [
            f"--dataSize={data_size}",
            f"--installparamsSize={installparams_size}"
        ]
        # Call ledgerblue
        ledgerblue(args + sys.argv[2:])

    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)

def ledgerblue(args: List[str]):
    """Dirty wrapper around ledgerblue"""
    subprocess.run([sys.executable, '-m', 'ledgerblue.loadApp'] + args)

if __name__ == "__main__":
    main()
