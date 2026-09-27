# MATLAB

The MATLAB script prepares an input image for the FPGA-based 2-D 5/3 DWT architecture. It accepts any image with even dimensions, converts RGB images to grayscale, preserves the original image size, and converts the pixel data into the required row-major format. It then generates the `Image_Hex_Generate` file, which is used as the input image data by the Verilog DWT architecture.
