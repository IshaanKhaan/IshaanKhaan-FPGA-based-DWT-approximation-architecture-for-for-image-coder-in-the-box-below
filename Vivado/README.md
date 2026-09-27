# Vivado

This folder contains the Verilog RTL design and simulation files for the FPGA-based 2-D 5/3 DWT architecture.

## Architecture

The design is divided into a control unit and a datapath. The top-level module connects both blocks and provides the input image to the datapath.

~~~text
                         DWTarc.v
                            |
              +-------------+-------------+
              |                           |
       controlunit.v                 Datapath.v
              |                           |
              | control signals          | DWT computation
              +-------------+-------------+
                            |
                  H, L, HH, HL, LH, LL
~~~

The processing sequence is:

~~~text
Input Image
300 x 332
    |
    v
Load Image Memory
    |
    v
Horizontal 5/3 DWT
    |
    +------------------+
    |                  |
    v                  v
H: 300 x 166       L: 300 x 166
    |                  |
    +--------+---------+
             |
             v
       Vertical 5/3 DWT
             |
     +-------+-------+-------+
     |       |       |       |
     v       v       v       v
    HH      HL      LH      LL
150x166  150x166  150x166  150x166
~~~

## 1. DWTarc.v — Top-Level Module

DWTarc.v is the top-level module of the architecture. It connects the control unit and datapath and provides the interface for the complete DWT operation.

Its main functions are:

- Stores the input image memory.
- Reads input_image.hex using $readmemh.
- Provides the image data to the datapath during the load stage.
- Instantiates controlunit.v.
- Instantiates Datapath.v.
- Connects the control signals between the control unit and datapath.
- Provides the H, L, HH, HL, LH and LL outputs.
- Provides busy, done, horizontal_valid and vertical_valid status signals.

The current implementation uses a 300 × 332 image, while the dimensions are kept as parameters.

## 2. controlunit.v — Control and Sequencing

controlunit.v controls the sequence of operations performed by the datapath.

It uses a finite-state machine with the following states:

~~~text
       RESET
         |
         v
        LOAD
         |
         v
     HORIZONTAL
         |
         v
       VERTICAL
         |
         v
        DONE
~~~

### RESET

Initializes the counters and prepares the architecture to start processing.

### LOAD

Loads all 99,600 image pixels into the datapath image memory.

- One pixel is addressed per clock cycle.
- Address range: 0 to 99,599.

### HORIZONTAL

Controls the horizontal 5/3 DWT.

- Processes 300 rows.
- Produces 166 H/L pairs per row.
- Total H coefficients: 49,800.
- Total L coefficients: 49,800.

### VERTICAL

Controls the vertical 5/3 DWT.

- Processes the H and L intermediate data.
- Produces one HH, HL, LH and LL group per clock.
- Total coefficients per final subband: 24,900.

### DONE

Indicates that the complete DWT operation has finished.

## 3. Datapath.v — DWT Computation

Datapath.v performs the actual 5/3 DWT arithmetic.

It contains:

- Input image memory.
- H and L intermediate memories.
- Horizontal DWT combinational logic.
- Vertical DWT combinational logic.
- Sequential registers for the output coefficients.

### Horizontal Stage

For each input row, the datapath calculates:

~~~text
Input row
   |
   +----> High-pass filter ----> H
   |
   +----> Low-pass filter  ----> L
~~~

The high-pass operation is:

~~~text
H[n] = -x[2n-1] + 2x[2n] - x[2n+1]
~~~

The low-pass operation is:

~~~text
L[n] = -x[2n-1] + 2x[2n]
       + 6x[2n+1] + 2x[2n+2] - x[2n+3]
~~~

The resulting H and L coefficients are stored in intermediate memories.

### Vertical Stage

The vertical stage applies the same 5/3 filtering operation to the H and L intermediate data:

~~~text
                    H
                    |
              +-----+-----+
              |           |
          High-pass    Low-pass
              |           |
             HH          HL

                    L
                    |
              +-----+-----+
              |           |
          High-pass    Low-pass
              |           |
             LH          LL
~~~

Therefore:

- H → HH and HL
- L → LH and LL

The LL output uses 17 bits because its coefficient range requires one additional bit compared with the other outputs.

## 4. DWTarc_TB.v — Simulation Testbench

DWTarc_TB.v is used only for behavioral simulation. It is not synthesized as part of the FPGA design.

The testbench:

1. Generates the clock.
2. Applies reset.
3. Instantiates DWTarc.
4. Waits for the done signal.
5. Captures H and L coefficients when horizontal_valid is asserted.
6. Captures HH, HL, LH and LL coefficients when vertical_valid is asserted.
7. Writes the captured architecture outputs to HEX files.

The generated files are:

~~~text
H_arch.hex
L_arch.hex
HH_arch.hex
HL_arch.hex
LH_arch.hex
LL_arch.hex
~~~

MATLAB is then used for the final coefficient-by-coefficient comparison.

## 5. Complete Working Flow

~~~text
             input_image.hex
                    |
                    v
               +---------+
               | DWTarc  |
               +----+----+
                    |
          +---------+---------+
          |                   |
          v                   v
   controlunit.v          Datapath.v
          |                   |
          |             5/3 DWT arithmetic
          |                   |
          +---------+---------+
                    |
                    v
          H, L, HH, HL, LH, LL
                    |
                    v
             DWTarc_TB.v
                    |
                    v
          Architecture HEX files
                    |
                    v
          MATLAB coefficient
              comparison
~~~

## 6. Current Architecture Dimensions

| Stage | Dimensions | Number of coefficients |
|---|---:|---:|
| Input image | 300 × 332 | 99,600 |
| H | 300 × 166 | 49,800 |
| L | 300 × 166 | 49,800 |
| HH | 150 × 166 | 24,900 |
| HL | 150 × 166 | 24,900 |
| LH | 150 × 166 | 24,900 |
| LL | 150 × 166 | 24,900 |

The four final subbands together contain:

~~~text
24,900 × 4 = 99,600 coefficients
~~~

## 7. File Summary

| File | Purpose |
|---|---|
| DWTarc.v | Top-level architecture and module connections |
| controlunit.v | FSM, counters and processing control |
| Datapath.v | 5/3 DWT arithmetic and coefficient memories |
| DWTarc_TB.v | Behavioral simulation and HEX output generation |
| input_image.hex | Input image data used by the Verilog simulation |

## 8. Verification

The Vivado architecture was verified against the MATLAB DWT reference on the same 300 × 332 input image.

The final coefficient comparison checks all:

- 49,800 H coefficients
- 49,800 L coefficients
- 24,900 HH coefficients
- 24,900 HL coefficients
- 24,900 LH coefficients
- 24,900 LL coefficients

Final result:

~~~text
Total final-subband coefficients = 99,600
Matches                          = 99,600
Mismatches                       = 0
Matching percentage              = 100.00%
~~~


## Input Image Used

The project uses **newdog.jpeg** as the input image for the demonstrated 2-D 5/3 DWT implementation.

The image is converted to grayscale without resizing. Its dimensions are **300 × 332**, giving **99,600 input pixels**. MATLAB converts the grayscale image into row-major hexadecimal data in \`input_image.hex\`.

The same \`input_image.hex\` file is loaded by \`DWTarc.v\` using \`$readmemh\` and is therefore the input data processed by the Vivado DWT architecture.

~~~text
Input Image
newdog.jpeg
     |
     v
MATLAB DWT reference / HEX generation
     |
     v
input_image.hex
     |
     v
DWTarc.v
     |
     v
2-D 5/3 DWT
~~~
