%Generate 100 photos for evaluation
clc; clear; close all;
imPath = 'Lenna.png'; % put the path to your image here, e.g. C:\Users\Downloads\jpeg_computing\Lenna_small.png
% Colored image in any format supported by MATLAB
input_image = imread(imPath);

folderpath1 = './output_images/luv';
folderpath2 = './output_images/ycbcr';
status1 = mkdir(folderpath1);
status2 = mkdir(folderpath2);

if (status1 && status2)
    disp('output folder created successfully');
else
    disp('output directory creation failed');
    disp(['please create ./output_folder/luv and ./output_folder/ycbcr folders' ...
        'manually, the output images will be stored there']);
end

chrominance_subsampling = 2;%<---- CHANGE THIS PARAMETER
%chrominance_subsampling is the subsampling coefficient for chrominance
%it must be a power of 2 and less than min(dim1, dim2)/8

%see how image quality varies with this parameter
%and see how the compression ratio (of the file size) changes

ratio = zeros(100, 2);%this matix stores ratios, first column LUV, second column YCBCR

%CHANGE THESE TO RUN A LIMITED RANGE OF QUALITIES
upper = 100;
lower = 1;
%the values should be positive integers

for i = upper: -1: lower
    quality = i;

    %INTERMEDIATE FORMAT is CIELUV
    tic;
    %chrominance_ds_coef is the subsampling coefficient for chrominance
    %it must be a power of 2 and less than min(dim1, dim2)/8
    [output_image, ~, ratio(i, 1) ] = jpeg_computing_luv(input_image, quality, chrominance_subsampling);
    %[output_image, compressed_vector, ratio ] = jpeg_computing_old(input_image, quality);
    toc;
    
    %write image to ./output_images

    imwrite(output_image, ['./output_images/luv/luv_', num2str(i), '.png']);
    
    %=========================================================================

    %INTERMEDIATE FORMAT is YCBCR
    tic;
    %chrominance_ds_coef is the subsampling coefficient for chrominance
    %it must be a power of 2 and less than min(dim1, dim2)/8
    [output_image, ~, ratio(i, 2) ] = jpeg_computing_ycbcr(input_image, quality, chrominance_subsampling);
    toc;
    imwrite(output_image, ['./output_images/ycbcr/ycbcr_', num2str(i), '.png']);
end

%Save ratio information to ratio_100.mat
%=========================================================================================
save('ratio_100.mat', 'ratio');


%=========================================================================================
% Load the saved ratio information
load('ratio_100.mat');

% Define the quality parameter range
quality_range = lower:upper;

% Plot the compression ratios
figure;
hold on;
plot(quality_range, ratio(quality_range, 1), '-o', 'DisplayName', 'LUV');
plot(quality_range, ratio(quality_range, 2), '-x', 'DisplayName', 'YCbCr');
hold off;

% Add labels and title
xlabel('Quality Parameter');
ylabel('Compression Ratio');
title('Compression Ratio vs. Quality Parameter');
legend('show');
grid on;

% Save the figure
saveas(gcf, 'compression_ratio_vs_quality.png'); 


