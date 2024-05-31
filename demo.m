clc; clear; close all;
imPath = 'Lenna.png'; % put the path to your image here, e.g. C:\Users\Downloads\jpeg_computing\Lenna_small.png
input_image = imread(imPath);



quality = 100; %<---- CHANGE THIS PARAMETER
%see how image quality varies with this parameter
%and see how the compression ratio (of the file size) changes



% Colored image in any format supported by MATLAB
[ output_image, compressed_vector, ratio ] = jpeg_computing(input_image, quality);

% Gray colored image
%[ output_image, compressed_vector, ratio ] = jpeg_computing(rgb2gray(input_image), quality);
