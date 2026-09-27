# FPGA-Based 2-D 5/3 DWT Approximation Architecture for Image Coding

This repository contains the development of an FPGA-based 2-D Discrete Wavelet Transform (DWT) architecture for image coding and compression.

## Project Flow

MATLAB reference -> Behavioral Verilog -> Architectural Verilog -> Approximation/optimization -> FPGA verification

## Current Status

- Input image: newdog.jpeg
- Image size: 300 x 332
- RGB image converted to grayscale
- No resizing
- Total input pixels: 99,600
- Wavelet: 5/3 DWT
- Horizontal H/L verification: PASS, 0 mismatches
- Full 2-D behavioral verification completed
- Approximation is permitted in the project, so small coefficient differences are retained in the current baseline.

## 5/3 DWT Equations

High-pass:
H[n] = -x[2n-1] + 2x[2n] - x[2n+1]

Low-pass:
L[n] = -x[2n-1] + 2x[2n] + 6x[2n+1] + 2x[2n+2] - x[2n+3]

Boundary conditions used by the MATLAB reference:
- HPF: x[-1] = x[1], x[N] = x[N-2]
- LPF: x[-1] = x[2], x[N] = x[N-2], x[N+1] = x[N-3]

## Data Dimensions

Input: 300 x 332

After horizontal filtering and downsampling:
- H: 300 x 166
- L: 300 x 166

After vertical filtering and downsampling:
- HH: 150 x 166
- HL: 150 x 166
- LH: 150 x 166
- LL: 150 x 166

Each final subband contains 24,900 coefficients.

## Current Verification Results

| Subband | MATLAB | Vivado | Mismatches |
|---|---:|---:|---:|
| HH | 24,900 | 24,900 | 128 |
| HL | 24,900 | 24,900 | 271 |
| LH | 24,900 | 24,900 | 168 |
| LL | 24,900 | 24,900 | 340 |
| Total | 99,600 | 99,600 | 907 |

Total mismatch rate: approximately 0.91%.

The differences are small coefficient-level deviations in the current approximate implementation. The horizontal stage is exact.

## First 10 Reference Values

H:  -2 0 1 0 2 -1 0 1 2 1
L:  702 705 713 714 729 735 737 747 763 770

HH: -4 2 2 -2 2 -4 2 2 -2 2
HL: -4 -6 2 5 9 4 -6 2 22 2
LH: -2 -12 0 -16 -2 -2 -12 0 -16 2
LL: 5614 5668 5695 5758 5829 5878 5924 5968 6144 6148

## Behavioral Verilog

The behavioral reference module reads the image memory and generates:
- H_vivado.hex
- L_vivado.hex
- HH_vivado.hex
- HL_vivado.hex
- LH_vivado.hex
- LL_vivado.hex

The simulation completed successfully.

Vivado waveform messages about exceeding the 65,536-bit display limit are waveform display warnings and do not indicate a simulation calculation failure.

## Planned FPGA Architecture

DWTarc.v is intended to coordinate Datapath.v and controlunit.v. DWTarc_tb.v will be used for architectural verification.

## Repository Structure

MATLAB/
- DWT_reference.m
- Coefficient_Comparison.m
- twobandcompare.m
- input_image.hex

Verilog/
- Dwtfinal.v
- DWTarc.v
- Datapath.v
- controlunit.v
- DWTarc_tb.v

Results/
- HH_vivado.hex
- HL_vivado.hex
- LH_vivado.hex
- LL_vivado.hex

Documentation/
- DWT_REFERENCE.md
- VERIFICATION.md

## Project Objective

The final objective is to implement the 2-D 5/3 DWT on FPGA while exploring an approximate architecture that can reduce hardware cost and/or complexity while maintaining acceptable transform accuracy.
