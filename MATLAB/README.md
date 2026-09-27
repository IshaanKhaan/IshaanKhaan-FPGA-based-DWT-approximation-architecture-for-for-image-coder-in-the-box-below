# MATLAB

The MATLAB script prepares an input image for the FPGA-based 2-D 5/3 DWT architecture. It accepts any image with even dimensions, converts RGB images to grayscale, preserves the original image size, and converts the pixel data into the required row-major format. It then generates the `Image_Hex_Generate` file, which is used as the input image data by the Verilog DWT architecture.


## input_image.hex

The script generates `input_image.hex` from the selected grayscale image. The HEX file contains the image pixels in row-major order, with one 8-bit pixel value per line. For the project input `newdog.jpeg`, the generated file contains 99,600 pixel values and is the input data used by the Vivado DWT architecture.
