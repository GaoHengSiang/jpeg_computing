clc; clear; close all;
imPath = 'Lenna.png'; % put the path to your image here, e.g. C:\Users\Downloads\jpeg_computing\Lenna_small.png
input_image = imread(imPath);


R_comp = input_image(:, :, 1);

quality = 100; %<---- CHANGE THIS PARAMETER
%see how image quality varies with this parameter
%and see how the compression ratio (of the file size) changes
tic;
[X, Y, Z] = rgb2xyz(input_image(:, :, 1), input_image(:, :, 2), input_image(:, :, 3));
[R, G, B] = xyz2rgb(X, Y, Z);
toc;
output_image = cat(3, R, G, B);
subplot(1,2,1), imshow(input_image) % show results
subplot(1,2,2), imshow(output_image) % show results

% Colored image in any format supported by MATLAB
%=========================================================================================
%[ output_image, compressed_vector, ratio ] = jpeg_computing(input_image, quality);

% Gray colored image
%=========================================================================================
%[ output_image, compressed_vector, ratio ] = jpeg_computing(rgb2gray(input_image), quality);
