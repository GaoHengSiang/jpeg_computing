function [X, Y, Z] = rgb2xyz (r, g, b)
% Author: Hans Gao
% Color conversion algorithm referencing https://www.easyrgb.com/en/math.php
% With splendid help from Chat-GPT4o

%INPUT FORMAT = UINT8
%OUTPUT FORMAT = DOUBLE

%conversion on a 

    r = double(r);
    g = double(g);
    b = double(b);
    % Normalize the RGB values
    var_R = r / 255;
    var_G = g / 255;
    var_B = b / 255;
    
    % Apply the gamma correction
    gammaCorrect = @(c) ((c + 0.055) / 1.055) .^ 2.4 .* (c > 0.04045) + c / 12.92 .* (c <= 0.04045);
    var_R = gammaCorrect(var_R);
    var_G = gammaCorrect(var_G);
    var_B = gammaCorrect(var_B);
    
    % Scale to [0, 100]
    var_R = var_R * 100;
    var_G = var_G * 100;
    var_B = var_B * 100;
    
    % Reshape the matrices into vectors for matrix multiplication
    [rows, cols] = size(r);
    var_R = var_R(:);
    var_G = var_G(:);
    var_B = var_B(:);
    
    % Concatenate into a 3xN matrix where N is the number of pixels
    RGB = [var_R'; var_G'; var_B'];
    
    % Transformation matrix from RGB to XYZ
    M = [0.4124, 0.3576, 0.1805; 
         0.2126, 0.7152, 0.0722; 
         0.0193, 0.1192, 0.9505];
     
    % Apply the transformation matrix
    XYZ = M * RGB;
    
    % Reshape the results back to the original image size
    X = reshape(XYZ(1, :), [rows, cols]);
    Y = reshape(XYZ(2, :), [rows, cols]);
    Z = reshape(XYZ(3, :), [rows, cols]);
end
