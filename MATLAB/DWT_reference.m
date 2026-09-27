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

HALF_ROWS = IMAGE_ROWS / 2;
HALF_COLS = IMAGE_COLS / 2;

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

disp(double(original_row_major(1:min(10,end))).');

% ============================================================
% INITIALIZE HORIZONTAL DWT MATRICES
%
% Input:
% IMAGE_ROWS x IMAGE_COLS
%
% Output:
% H = IMAGE_ROWS x HALF_COLS
% L = IMAGE_ROWS x HALF_COLS
% ============================================================

H = zeros(IMAGE_ROWS, HALF_COLS);
L = zeros(IMAGE_ROWS, HALF_COLS);

% ============================================================
% HORIZONTAL 5/3 DWT
%
% HPF:
% H[n] = -x[2n-1] + 2*x[2n] - x[2n+1]
%
% LPF:
% L[n] = -x[2n-1] + 2*x[2n]
%        + 6*x[2n+1] + 2*x[2n+2] - x[2n+3]
%
% IMPORTANT PROJECT BOUNDARY CONVENTIONS:
%
% HPF left boundary:
% x[-1] = x[1]
%
% LPF left boundary:
% x[-1] = x[2]
%
% LPF right boundary:
% x[N]   = x[N-3]
% x[N+1] = x[N-4]
%
% For example, for a 15-sample signal:
% x[15] = x[12]
% and the next required extension would be x[16] = x[11].
%
% MATLAB indices are one greater than these mathematical indices.
% ============================================================

for row = 1:IMAGE_ROWS

    for n = 0:HALF_COLS-1

        % ====================================================
        % HIGH-PASS
        % ====================================================

        % x[2n-1]
        if n == 0
            % Project convention: x[-1] = x[1]
            xm1 = double(img(row, 2));
        else
            xm1 = double(img(row, 2*n));
        end

        % x[2n]
        x0 = double(img(row, 2*n + 1));

        % x[2n+1]
        if (2*n + 2) >= IMAGE_COLS
            % Right HPF boundary:
            % x[N] = x[N-2]
            xp1 = double(img(row, IMAGE_COLS-1));
        else
            xp1 = double(img(row, 2*n + 2));
        end

        H(row, n+1) = ...
            -xm1 ...
            + 2*x0 ...
            - xp1;

        % ====================================================
        % LOW-PASS
        % ====================================================

        % x[2n-1]
        if n == 0
            % IMPORTANT:
            % Project convention is x[-1] = x[2]
            % MATLAB index for x[2] is 3.
            xm2 = double(img(row, 3));
        else
            xm2 = double(img(row, 2*n));
        end

        % x[2n]
        xm1_low = double(img(row, 2*n + 1));

        % x[2n+1]
        x0_low = double(img(row, 2*n + 2));

        % x[2n+2]
        if (2*n + 3) >= IMAGE_COLS
            % Right LPF boundary:
            % x[N] = x[N-3]
            % MATLAB index for x[N-3] is IMAGE_COLS-2.
            xp1_low = double(img(row, IMAGE_COLS-2));
        else
            xp1_low = double(img(row, 2*n + 3));
        end

        % x[2n+3]
        if (2*n + 4) >= IMAGE_COLS
            % Right LPF boundary:
            % x[N+1] = x[N-4]
            % MATLAB index for x[N-4] is IMAGE_COLS-3.
            xp2_low = double(img(row, IMAGE_COLS-3));
        else
            xp2_low = double(img(row, 2*n + 4));
        end

        L(row, n+1) = ...
            -xm2 ...
            + 2*xm1_low ...
            + 6*x0_low ...
            + 2*xp1_low ...
            - xp2_low;

    end
end

% ============================================================
% DISPLAY HORIZONTAL RESULTS
% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('HORIZONTAL 5/3 DWT\n');
fprintf('============================================\n');

fprintf('\n');
fprintf('H size = %d x %d\n', size(H,1), size(H,2));
fprintf('L size = %d x %d\n', size(L,1), size(L,2));

fprintf('\n');
fprintf('FIRST 10 HIGH-PASS SCALED VALUES\n');
disp(H(1,1:min(10,HALF_COLS)));

fprintf('\n');
fprintf('FIRST 10 LOW-PASS SCALED VALUES\n');
disp(L(1,1:min(10,HALF_COLS)));

% ============================================================
% INITIALIZE FINAL 2-D DWT MATRICES
%
% HH, HL, LH, LL:
% HALF_ROWS x HALF_COLS
% ============================================================

HH = zeros(HALF_ROWS, HALF_COLS);
HL = zeros(HALF_ROWS, HALF_COLS);
LH = zeros(HALF_ROWS, HALF_COLS);
LL = zeros(HALF_ROWS, HALF_COLS);

% ============================================================
% VERTICAL 5/3 DWT
%
% H -> HH + HL
% L -> LH + LL
%
% The same 0-based DWT indexing and boundary conventions
% used horizontally are applied vertically.
% ============================================================

for col = 1:HALF_COLS

    for n = 0:HALF_ROWS-1

        % ====================================================
        % H -> HH
        % VERTICAL HIGH-PASS
        % ====================================================

        % H[2n-1]
        if n == 0
            % HPF convention: H[-1] = H[1]
            a = H(2, col);
        else
            a = H(2*n, col);
        end

        % H[2n]
        b = H(2*n + 1, col);

        % H[2n+1]
        if (2*n + 2) >= IMAGE_ROWS
            % Right HPF boundary: H[N] = H[N-2]
            c = H(IMAGE_ROWS-1, col);
        else
            c = H(2*n + 2, col);
        end

        HH(n+1, col) = ...
            -a ...
            + 2*b ...
            - c;

        % ====================================================
        % H -> HL
        % VERTICAL LOW-PASS
        % ====================================================

        % H[2n-1]
        if n == 0
            % IMPORTANT:
            % LPF convention: H[-1] = H[2]
            % MATLAB row index for H[2] is 3.
            a = H(3, col);
        else
            a = H(2*n, col);
        end

        % H[2n]
        b = H(2*n + 1, col);

        % H[2n+1]
        c = H(2*n + 2, col);

        % H[2n+2]
        if (2*n + 3) >= IMAGE_ROWS
            % Right LPF boundary: H[N] = H[N-3]
            % MATLAB row index for H[N-3] is IMAGE_ROWS-2.
            d = H(IMAGE_ROWS-2, col);
        else
            d = H(2*n + 3, col);
        end

        % H[2n+3]
        if (2*n + 4) >= IMAGE_ROWS
            % Right LPF boundary: H[N+1] = H[N-4]
            % MATLAB row index for H[N-4] is IMAGE_ROWS-3.
            e = H(IMAGE_ROWS-3, col);
        else
            e = H(2*n + 4, col);
        end

        HL(n+1, col) = ...
            -a ...
            + 2*b ...
            + 6*c ...
            + 2*d ...
            - e;

        % ====================================================
        % L -> LH
        % VERTICAL HIGH-PASS
        % ====================================================

        % L[2n-1]
        if n == 0
            % HPF convention: L[-1] = L[1]
            a = L(2, col);
        else
            a = L(2*n, col);
        end

        % L[2n]
        b = L(2*n + 1, col);

        % L[2n+1]
        if (2*n + 2) >= IMAGE_ROWS
            % Right HPF boundary: L[N] = L[N-2]
            c = L(IMAGE_ROWS-1, col);
        else
            c = L(2*n + 2, col);
        end

        LH(n+1, col) = ...
            -a ...
            + 2*b ...
            - c;

        % ====================================================
        % L -> LL
        % VERTICAL LOW-PASS
        % ====================================================

        % L[2n-1]
        if n == 0
            % IMPORTANT:
            % LPF convention: L[-1] = L[2]
            % MATLAB row index for L[2] is 3.
            a = L(3, col);
        else
            a = L(2*n, col);
        end

        % L[2n]
        b = L(2*n + 1, col);

        % L[2n+1]
        c = L(2*n + 2, col);

        % L[2n+2]
        if (2*n + 3) >= IMAGE_ROWS
            % Right LPF boundary: L[N] = L[N-3]
            % MATLAB row index for L[N-3] is IMAGE_ROWS-2.
            d = L(IMAGE_ROWS-2, col);
        else
            d = L(2*n + 3, col);
        end

        % L[2n+3]
        if (2*n + 4) >= IMAGE_ROWS
            % Right LPF boundary: L[N+1] = L[N-4]
            % MATLAB row index for L[N-4] is IMAGE_ROWS-3.
            e = L(IMAGE_ROWS-3, col);
        else
            e = L(2*n + 4, col);
        end

        LL(n+1, col) = ...
            -a ...
            + 2*b ...
            + 6*c ...
            + 2*d ...
            - e;

    end
end

% ============================================================
% 2-D DWT RESULTS
% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('2-D 5/3 DWT RESULTS\n');
fprintf('============================================\n');

fprintf('\n');
fprintf('HH size = %d x %d\n', size(HH,1), size(HH,2));
fprintf('HL size = %d x %d\n', size(HL,1), size(HL,2));
fprintf('LH size = %d x %d\n', size(LH,1), size(LH,2));
fprintf('LL size = %d x %d\n', size(LL,1), size(LL,2));

% ============================================================
% CONVERT OUTPUTS TO ROW-MAJOR LINEAR ORDER
%
% MATLAB is column-major.
% Verilog is row-major.
%
% Transpose before linear indexing.
% ============================================================

HH_row_major = HH.';
HL_row_major = HL.';
LH_row_major = LH.';
LL_row_major = LL.';

% ============================================================
% DISPLAY FIRST 10 VALUES IN ROW-MAJOR ORDER
%
% These correspond directly to:
% Verilog HH[0] to HH[9]
% Verilog HL[0] to HL[9]
% Verilog LH[0] to LH[9]
% Verilog LL[0] to LL[9]
% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('FIRST 10 HH VALUES - ROW MAJOR\n');
fprintf('============================================\n');
disp(HH_row_major(1:min(10,end)).');

fprintf('\n');
fprintf('============================================\n');
fprintf('FIRST 10 HL VALUES - ROW MAJOR\n');
fprintf('============================================\n');
disp(HL_row_major(1:min(10,end)).');

fprintf('\n');
fprintf('============================================\n');
fprintf('FIRST 10 LH VALUES - ROW MAJOR\n');
fprintf('============================================\n');
disp(LH_row_major(1:min(10,end)).');

fprintf('\n');
fprintf('============================================\n');
fprintf('FIRST 10 LL VALUES - ROW MAJOR\n');
fprintf('============================================\n');
disp(LL_row_major(1:min(10,end)).');

% ============================================================
% COMPLETE
% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('COMPLETE 2-D DWT\n');
fprintf('============================================\n');

fprintf('Input image : %d x %d\n', IMAGE_ROWS, IMAGE_COLS);
fprintf('H           : %d x %d\n', IMAGE_ROWS, HALF_COLS);
fprintf('L           : %d x %d\n', IMAGE_ROWS, HALF_COLS);
fprintf('HH          : %d x %d\n', HALF_ROWS, HALF_COLS);
fprintf('HL          : %d x %d\n', HALF_ROWS, HALF_COLS);
fprintf('LH          : %d x %d\n', HALF_ROWS, HALF_COLS);
fprintf('LL          : %d x %d\n', HALF_ROWS, HALF_COLS);

fprintf('\n');
fprintf('DWT PROCESS COMPLETE.\n');
save('DWT_reference.mat', 'HH', 'HL', 'LH', 'LL');
