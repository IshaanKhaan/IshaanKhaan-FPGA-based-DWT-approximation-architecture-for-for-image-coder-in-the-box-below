clc;
clear;
close all;

% ============================================================
% LOAD IMAGE
% ============================================================

[file, path] = uigetfile( ...
    {'*.jpg;*.jpeg;*.png;*.bmp', 'Image Files'}, ...
    'Select Input Image');

if isequal(file, 0)
    error('No image selected.');
end

img = imread(fullfile(path, file));

% Convert RGB image to grayscale if necessary
if ndims(img) == 3
    img = rgb2gray(img);
end

% Do NOT resize the image
img = uint8(img);

% ============================================================
% IMAGE INFORMATION
% ============================================================

IMAGE_ROWS = size(img, 1);
IMAGE_COLS = size(img, 2);

if mod(IMAGE_ROWS, 2) ~= 0 || mod(IMAGE_COLS, 2) ~= 0
    error('Image dimensions must be even.');
end

fprintf('\n');
fprintf('============================================\n');
fprintf('IMAGE INFORMATION\n');
fprintf('============================================\n');
fprintf('Image size: %d x %d\n', IMAGE_ROWS, IMAGE_COLS);
fprintf('Data type: %s\n', class(img));
fprintf('Minimum pixel value: %d\n', min(img(:)));
fprintf('Maximum pixel value: %d\n', max(img(:)));
fprintf('Total pixels: %d\n', numel(img));

% ============================================================
% GENERATE HEX FILE
%
% Verilog uses row-major storage:
% image_mem[row*IMAGE_COLS + col]
%
% MATLAB internally uses column-major storage.
% Transpose before linearizing.
% ============================================================

fid = fopen('input_image.hex', 'w');

if fid == -1
    error('Could not create input_image.hex');
end

img_row_major = img.';

for i = 1:numel(img_row_major)
    fprintf(fid, '%02X\n', img_row_major(i));
end

fclose(fid);

fprintf('\n');
fprintf('HEX file generated successfully.\n');
fprintf('File name: input_image.hex\n');
fprintf('Total pixels written: %d\n', numel(img));

% ============================================================
% VERIFY HEX FILE
% ============================================================

fid = fopen('input_image.hex', 'r');

if fid == -1
    error('Could not open input_image.hex for verification.');
end

hex_data = textscan(fid, '%s');
fclose(fid);

hex_data = hex_data{1};
hex_decimal = uint8(hex2dec(hex_data));

fprintf('\n');
fprintf('Number of HEX values read: %d\n', length(hex_decimal));

original_row_major = img_row_major(:);

if isequal(hex_decimal, original_row_major)
    fprintf('\n');
    fprintf('HEX verification: PASSED\n');
    fprintf('Original MATLAB image and HEX data are identical.\n');
else
    error('HEX verification FAILED.');
end

% ============================================================
% FIRST 10 INPUT PIXELS
% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('FIRST 10 INPUT PIXELS\n');
fprintf('============================================\n');

disp(double(original_row_major(1:min(10, end))).');
