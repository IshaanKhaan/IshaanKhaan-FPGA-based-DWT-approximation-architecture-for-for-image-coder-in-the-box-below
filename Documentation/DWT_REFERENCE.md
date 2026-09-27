# 2-D 5/3 DWT Reference

## Input
- Image: newdog.jpeg
- Size: 300 x 332
- Converted to grayscale
- No resizing
- Total pixels: 99,600

## Filters

High-pass:
H[n] = -x[2n-1] + 2x[2n] - x[2n+1]

Low-pass:
L[n] = -x[2n-1] + 2x[2n] + 6x[2n+1] + 2x[2n+2] - x[2n+3]

## Boundary Conditions

HPF:
- x[-1] = x[1]
- x[N] = x[N-2]

LPF:
- x[-1] = x[2]
- x[N] = x[N-2]
- x[N+1] = x[N-3]

## Dimensions

Input: 300 x 332

Horizontal:
- H = 300 x 166
- L = 300 x 166

Vertical:
- HH = 150 x 166
- HL = 150 x 166
- LH = 150 x 166
- LL = 150 x 166

## Reference Values

H: -2 0 1 0 2 -1 0 1 2 1

L: 702 705 713 714 729 735 737 747 763 770

HH: -4 2 2 -2 2 -4 2 2 -2 2

HL: -4 -6 2 5 9 4 -6 2 22 2

LH: -2 -12 0 -16 -2 -2 -12 0 -16 2

LL: 5614 5668 5695 5758 5829 5878 5924 5968 6144 6148
