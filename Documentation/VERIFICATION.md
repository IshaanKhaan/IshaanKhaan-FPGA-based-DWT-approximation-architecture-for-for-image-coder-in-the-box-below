# Verification

## Horizontal Verification

MATLAB vs Vivado:
- H mismatches: 0
- L mismatches: 0
- H: PASS
- L: PASS

## Full 2-D Behavioral Verification

| Subband | Coefficients | Mismatches |
|---|---:|---:|
| HH | 24,900 | 128 |
| HL | 24,900 | 271 |
| LH | 24,900 | 168 |
| LL | 24,900 | 340 |
| Total | 99,600 | 907 |

Mismatch rate: approximately 0.91%.

The project permits approximation, so the current baseline retains these small coefficient-level deviations.

## Simulation

The behavioral Verilog simulation completed successfully and generated:
- H_vivado.hex
- L_vivado.hex
- HH_vivado.hex
- HL_vivado.hex
- LH_vivado.hex
- LL_vivado.hex

Vivado waveform messages concerning the 65,536-bit display limit are display warnings and do not indicate a simulation calculation failure.

## Next Step

Verify the architectural RTL implementation using DWTarc.v, Datapath.v, controlunit.v, and DWTarc_tb.v once the architecture is completed.
