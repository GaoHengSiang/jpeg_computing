clc; clear; close all;
imPath = 'Lenna.png'; % put the path to your image here, e.g. C:\Users\Downloads\jpeg_computing\Lenna_small.png
input_image = imread(imPath);


R_comp = input_image(:, :, 1);

quality = 100; %<---- CHANGE THIS PARAMETER
%see how image quality varies with this parameter
%and see how the compression ratio (of the file size) changes


%=========================================================================================
%Testing rgb <--> xyz and xyz <--> rgb conversion
% [X, Y, Z] = rgb2xyz(input_image(:, :, 1), input_image(:, :, 2), input_image(:, :, 3));
% tic;
% [L, u, v] = xyz2luv(X, Y, Z);
% [X_, Y_, Z_] = luv2xyz(L, u, v);
% toc;
% [R, G, B] = xyz2rgb(X, Y, Z);
% output_image = cat(3, R, G, B);
%=======================================================
%Testing rgb <--> luv conversion
% tic;
% luvmap = rgb2luv(input_image);
% toc;
% tic;
% output_image = luv2rgb(luvmap);
% toc;
%=======================================================
% subplot(1,2,1), imshow(input_image) % show results
% subplot(1,2,2), imshow(output_image) % show results
%=========================================================================================


% Colored image in any format supported by MATLAB
%=========================================================================================
tic;
%chrominance_ds_coef is the subsampling coefficient for chrominance
%it must be a power of 2 and less than min(dim1, dim2)/8
[output_image, compressed_vector, ratio ] = jpeg_computing(input_image, quality, 2);
toc;

subplot(1,2,1), imshow(input_image); % show results
subplot(1,2,2), imshow(output_image); % show results
% Gray colored image
%=========================================================================================
%[ output_image, compressed_vector, ratio ] = jpeg_computing(rgb2gray(input_image), quality);
