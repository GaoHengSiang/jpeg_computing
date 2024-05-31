function [ output_image, compressed_vector, ratio ] = jpeg_computing( input_image, q, chrominance_ds_coef)
%INPUT_FORMAT = IMAGE in UNIT8, w/ or w/o RGB channels
% q is a quality (from 1 to 100 percent), 100 - the best quality and low
% compression, too little values (less than 10) are not guaranteed to work

%OUTPUT_FORMAT = IMAGE in UINT8, lossy (as a result of chrominance subsampling and
%quantization)

%compressed_vector: Binary Sequence which is huffman code (VLC, variable
%length code) and VLI(variable length integer) interleaved.

%ratio is the bit ratio of the input_image to the compressed_vector

%---------------------------
% define init values
n = 8; % size of blocks
dim1 = size(input_image,1); % image width
dim2 = size(input_image,2); % image height
dim3 = size(input_image,3); % number of channels


if (dim3 == 3)
    luvmap = rgb2luv (input_image);
else if(dim3 == 1)
    luvmap = im2double (input_image);
    padding = zeros([dim1, dim2, 2]);
    luvmap = cat(3, luvmap, padding);
else
    disp("ERROR: input_image is not RGB nor grayscale")
end
%==============================================
%Implement Downsample of Chromatic Components

L = luvmap(:, :, 1);
u = luvmap(:, :, 2);
v = luvmap(:, :, 3);
u = downsample(u, chrominance_ds_coef);



% here you can (should) also paste downsampling of chroma components
output_image = zeros(size(input_image), 'double');

[qY, qC] = get_quantization(q); % get quantization matrices
T = dctmtx(n); % DCT matrix
scale = 255; % need because DCT values of YCbCr are too small to be quantized


% Block processing functions
dct = @(block_struct) T * block_struct.data * T';
invdct = @(block_struct) T' * block_struct.data * T;
quantY = @(block_struct) round( block_struct.data./qY);
dequantY = @(block_struct) block_struct.data.*qY;
quantC = @(block_struct) round( block_struct.data./qC);
dequantC = @(block_struct) block_struct.data.*qC;
entropy_proc = @(block_struct) entropy_cod(block_struct.data, n);

%initialize compressed vector
compressed_vector = false(0, 1);
%---------------------------
for ch=1:dim3
    % encoding ---------------------------
    channel = ycbcrmap(:,:,ch); % get channel
    % compute scaled forward DCT
    channel_dct = blockproc(channel, [n n], dct, 'PadPartialBlocks', true).*scale; 
    % quantization
    if (ch == 1)
        channel_q = blockproc(channel_dct,[n n], quantY);  % quantization for luma
    else
        channel_q = blockproc(channel_dct,[n n], quantC);  % quantization for colors
    end
    entropy_out = blockproc(channel_q,[n n], entropy_proc); % compute entropy code for the whole channel
    save("entropy_mat.mat", "entropy_out");%for testing purposes
        

    %------------------------------------------------------
    %RLE COMPRESSION
    %------------------------------------------------------
    [comp, AC_dict, DC_dict] = RLE_compression(entropy_out, n);
    %HOW TO CACULATE THE SIZE (in bits) OF DICT?


    compressed_vector = cat(1, compressed_vector, comp); % add to output

    % dequantization
    if (ch == 1)
        channel_q = blockproc(channel_q,[n n], dequantY);
    else
        channel_q = blockproc(channel_q,[n n], dequantC);
    end
    output_data = blockproc(channel_q./scale,[n n],invdct); % inverse DCT, scale back
    output_image(:,:,ch) = output_data(1:dim1, 1:dim2); % set output
end
%---------------------------

if (dim3 > 1)
    output_image = im2uint8(ycbcr2rgb(output_image)); % back to rgb uint8
else
    output_image = im2uint8(output_image); % back to rgb uint8
end
% compute compression ratio
% compressed_vector is binary, input image has one byte per pixel
ratio = dim1 * dim2 * dim3 *8 / (length(compressed_vector)); % size of huffman dicitonary  is missed
subplot(1,2,1), imshow(input_image) % show results
subplot(1,2,2), imshow(output_image) % show results
end 



