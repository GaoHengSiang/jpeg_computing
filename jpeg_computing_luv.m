function [output_image, compressed_vector, ratio ] = jpeg_computing( input_image, q, chrominance_ds_coef)
%INPUT_FORMAT = IMAGE in UNIT8, w/ or w/o RGB channels
% q is a quality (from 1 to 100 percent), 100 - the best quality and low
% compression, too little values (less than 10) are not guaranteed to work

%OUTPUT_FORMAT = IMAGE in UINT8, lossy (as a result of chrominance subsampling and
%quantization)

%compressed_vector: Binary Sequence which is huffman code (VLC, variable
%length code) and VLI(variable length integer) interleaved.

%ratio is the bit ratio of the input_image to the compressed_vector

%chrominance_ds_coef is the subsampling coefficient for chrominance
%it must be a power of 2 and less than min(dim1, dim2)/8
%---------------------------
% define init values
n = 8; % size of blocks
dim1 = size(input_image,1); % image width
dim2 = size(input_image,2); % image height
dim3 = size(input_image,3); % number of channels

L_range = 100;
u_range = 354;
v_range = 262;

disp("conversion to LUV format...");
if (dim3 == 3)
    luvmap = rgb2luv (input_image);
elseif (dim3 == 1)
    %no conversion to luv
    luvmap = im2double (input_image);
    padding = zeros([dim1, dim2, 2]);
    luvmap = cat(3, luvmap, padding);
else
    disp("ERROR: input_image is not RGB nor grayscale")
end
disp("DONE");
%==============================================
%Implement Downsample of Chromatic Components

L = luvmap(:, :, 1) / L_range; %range 0 ~ 100
u = luvmap(:, :, 2) / u_range; %range -134 ~ 220
v = luvmap(:, :, 3) / v_range; %range -140 ~ 122

disp("downsample...");
%makeshift downsampling block
u = downsample(u, chrominance_ds_coef);
u = downsample(u', chrominance_ds_coef);
u = u';
v = downsample(v, chrominance_ds_coef);
v = downsample(v', chrominance_ds_coef);
v = v';
[ch_dim1, ch_dim2] = size(u);
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
zig_zag_proc = @(block_struct) zig_zag_cod(block_struct.data, n);

%initialize compressed vector
%-------------------------------------------
%For Luminance Channel
%DCT BLOCK
disp("DCT...");
L_dct = blockproc(L, [n n], dct, 'PadPartialBlocks', true).*scale;
u_dct = blockproc(u, [n n], dct, 'PadPartialBlocks', true).*scale;
v_dct = blockproc(v, [n n], dct, 'PadPartialBlocks', true).*scale;
disp("DONE");

%QUANTIZE BLOCK
disp("quantize...");
L_q = blockproc(L_dct,[n n], quantY);  % quantization for Luminance
u_q = blockproc(u_dct,[n n], quantC);  % quantization for Chrominance
v_q = blockproc(v_dct,[n n], quantC);  % quantization for Chrominance
disp("DONE");

%zig_zag BLOCK
disp("zig_zag coding...");
L_ent = blockproc(int16(L_q), [n n], zig_zag_proc);
u_ent = blockproc(int16(u_q), [n n], zig_zag_proc);
v_ent = blockproc(int16(v_q), [n n], zig_zag_proc);
disp("DONE");

%RLE BLOCK & HUFFMAN BLOCK
[L_comp, L_AC_dict, L_DC_dict] = RLE_compression(L_ent, n);
disp("Luminance DONE");
[u_comp, u_AC_dict, u_DC_dict] = RLE_compression(u_ent, n);
disp("U Chrominance DONE");
[v_comp, v_AC_dict, v_DC_dict] = RLE_compression(v_ent, n);
disp("V Chrominance DONE");

compressed_vector = [L_comp; u_comp; v_comp];%stack along the first dimension

%===========================================================
%DEQUANTIZATION BLOCK
disp("dequantize...");
L_dct_loss = blockproc(L_q, [n n], dequantY);
u_dct_loss = blockproc(u_q, [n n], dequantC);
v_dct_loss = blockproc(v_q, [n n], dequantC);
disp("DONE");

%INVERSE DCT BLOCK
disp("inverse DCT...");
L_loss = blockproc(L_dct_loss./scale,[n n],invdct);
u_loss = blockproc(u_dct_loss./scale,[n n],invdct);
v_loss = blockproc(v_dct_loss./scale,[n n],invdct);
disp("DONE");

%UPSAMPLE
disp("upsample...");
L_loss = L_loss * L_range;
u_loss = zero_order_upsample(u_loss, chrominance_ds_coef) * u_range;
v_loss = zero_order_upsample(v_loss, chrominance_ds_coef) * v_range;
disp("DONE");

%CONVERT BACK TO RGB UNIT8
disp("conversion to RGB format...");
luvmap_loss = cat(3, L_loss, u_loss, v_loss);

if (dim3 == 3)
    output_image = luv2rgb(luvmap_loss);
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

