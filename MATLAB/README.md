# MATLAB

This folder contains the MATLAB scripts used to prepare the input image for the FPGA-based 2-D 5/3 DWT architecture.

## generate_input_hex.m

The `generate_input_hex.m` script converts an input image into the hexadecimal memory file used by the Verilog design.

### What the script does

1. Selects an input image using a file-selection dialog.
2. Converts an RGB image to grayscale when required.
3. Keeps the original image dimensions without resizing.
4. Checks that both image dimensions are even, as required by the DWT architecture.
5. Converts the MATLAB image data from column-major ordering to row-major ordering.
6. Generates the file:

```text
input_image.hex
```

7. Verifies that the generated HEX data is identical to the original image data in row-major order.
8. Displays the first 10 input pixel values.

### Row-major ordering

MATLAB stores matrices in column-major order, while the Verilog image memory is addressed in row-major order:

```text
image_mem[row*IMAGE_COLS + col]
```

Therefore, the script transposes the image before writing the HEX file. This ensures that the pixel ordering in `input_image.hex` matches the memory addressing used by the FPGA architecture.

### Input used for the current verification

The current project verification uses:

```text
newdog.jpeg
```

The image is converted to grayscale without resizing. Its dimensions are:

```text
300 x 332
```

This produces:

```text
99,600 input pixels
```

### Output

The generated `input_image.hex` file contains one 8-bit grayscale pixel value per line in hexadecimal format.

Example:

```text
57
58
58
58
59
59
59
59
5B
5B
```

The first 10 decimal pixel values for the current image are:

```text
87 88 88 88 89 89 89 89 91 91
```

The generated HEX file is subsequently loaded by the Verilog testbench and used as the input image for the DWT architecture.
