function [output_image, compressed_vector, ratio ] = jpeg_computing_ycbcr( input_image, q, chrominance_ds_coef)
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

range = 255;

disp("conversion to yCbCr format...");
if (dim3 == 3)
    ycbcrmap = double(rgb2ycbcr (input_image));
elseif (dim3 == 1)
    %no conversion to luv
    ycbcrmap = im2double (input_image);
    padding = zeros([dim1, dim2, 2]);
    ycbcrmap = cat(3, ycbcrmap, padding);
else
    disp("ERROR: input_image is not RGB nor grayscale")
end
disp("DONE");
%==============================================
%Implement Downsample of Chromatic Components

%range of Y, CB, CR are all 0 ~ 255

y = ycbcrmap(:, :, 1) / range; 
cb = ycbcrmap(:, :, 2) / range;
cr = ycbcrmap(:, :, 3) / range;

disp("downsample...");
%makeshift downsampling block
cb = downsample(cb, chrominance_ds_coef);
cb = downsample(cb', chrominance_ds_coef);
cb = cb';
cr = downsample(cr, chrominance_ds_coef);
cr = downsample(cr', chrominance_ds_coef);
cr = cr';
[ch_dim1, ch_dim2] = size(cb);
disp("DONE");

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
%-------------------------------------------
%For Luminance Channel
%DCT BLOCK
disp("DCT...");
y_dct = blockproc(y, [n n], dct, 'PadPartialBlocks', true).*scale;
cb_dct = blockproc(cb, [n n], dct, 'PadPartialBlocks', true).*scale;
cr_dct = blockproc(cr, [n n], dct, 'PadPartialBlocks', true).*scale;
disp("DONE");

%QUANTIZE BLOCK
disp("quantize...");
y_q = blockproc(y_dct,[n n], quantY);  % quantization for Luminance
cb_q = blockproc(cb_dct,[n n], quantC);  % quantization for Chrominance
cr_q = blockproc(cr_dct,[n n], quantC);  % quantization for Chrominance


disp("DONE");

%ENTROPY BLOCK
disp("entropy coding...");
y_ent = blockproc(int16(y_q), [n n], entropy_proc);
cb_ent = blockproc(int16(cb_q), [n n], entropy_proc);
cr_ent = blockproc(int16(cr_q), [n n], entropy_proc);
disp("DONE");

%RLE BLOCK & HUFFMAN BLOCK

[y_comp, y_AC_dict, y_DC_dict] = RLE_compression(y_ent, n);
[cb_comp, cb_AC_dict, cb_DC_dict] = RLE_compression(cb_ent, n);
[cr_comp, cr_AC_dict, cr_DC_dict] = RLE_compression(cr_ent, n);

compressed_vector = [y_comp; cb_comp; cr_comp];%stack along the first dimension

%===========================================================
%DEQUANTIZATION BLOCK
disp("dequantize...");
y_dct_loss = blockproc(y_q, [n n], dequantY);
cb_dct_loss = blockproc(cb_q, [n n], dequantC);
cr_dct_loss = blockproc(cr_q, [n n], dequantC);
disp("DONE");

%INVERSE DCT BLOCK
disp("inverse DCT...");
y_loss = blockproc(y_dct_loss./scale,[n n],invdct);
cb_loss = blockproc(cb_dct_loss./scale,[n n],invdct);
cr_loss = blockproc(cr_dct_loss./scale,[n n],invdct);
disp("DONE");

%UPSAMPLE
disp("upsample...");
y_loss = y_loss * range;
cb_loss = zero_order_upsample(cb_loss, chrominance_ds_coef) * range;
cr_loss = zero_order_upsample(cr_loss, chrominance_ds_coef) * range;
disp("DONE");

%CONVERT BACK TO RGB UNIT8
disp("conversion to RGB format...");
ycbcrmap_loss = cat(3, y_loss, cb_loss, cr_loss);


if (dim3 == 3)
    output_image = ycbcr2rgb(uint8(ycbcrmap_loss));
elseif (dim3 == 1)
    output_image = im2uint8(L_loss);
end
disp("DONE");

% compute compression ratio
% compressed_vector is binary, input image has one byte per pixel
ratio = dim1 * dim2 * dim3 *8 / (length(compressed_vector)); % size of huffman dicitonary  is missed
end 


%MAKESHIFT UPSAMPLE
function upsampled_image = zero_order_upsample(image, scale_factor)
    % image: Input image to be upsampled
    % scale_factor: Factor by which to upsample the image

    % Get the size of the original image
    [rows, cols, channels] = size(image);

    % Calculate the size of the upsampled image
    new_rows = round(rows * scale_factor);
    new_cols = round(cols * scale_factor);

    % Initialize the upsampled image
    upsampled_image = zeros(new_rows, new_cols, channels, 'like', image);

    % Generate the row and column indices for the original image
    row_indices = ceil((1:new_rows) / scale_factor);
    col_indices = ceil((1:new_cols) / scale_factor);

    % Assign the values from the original image to the upsampled image
    for c = 1:channels
        upsampled_image(:, :, c) = image(row_indices, col_indices, c);
    end
end

