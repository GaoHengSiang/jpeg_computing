function [r, g, b] = xyz2rgb (X, Y, Z)
% Author: Hans Gao
% Color conversion algorithm referencing https://www.easyrgb.com/en/math.php
% With splendid help from Chat-GPT4o

%INPUT FORMAT = DOUBLE
%OUTPUT FORMAT = UINT8

    % Normalize the XYZ values
    X = X / 100;
    Y = Y / 100;
    Z = Z / 100;

    % Reshape the matrices into vectors for matrix multiplication
    [rows, cols] = size(X);
    X = X(:);
    Y = Y(:);
    Z = Z(:);
    
    % Concatenate into a 3xN matrix where N is the number of pixels
    XYZ = [X'; Y'; Z'];

    % Transformation matrix from XYZ to RGB
    M_inv = [ 3.2406, -1.5372, -0.4986; 
             -0.9689,  1.8758,  0.0415; 
              0.0557, -0.2040,  1.0570];
    
    % Apply the transformation matrix
    RGB = M_inv * XYZ;
    
    % Extract the individual RGB components
    r = RGB(1, :)';
    g = RGB(2, :)';
    b = RGB(3, :)';
    
    % Apply the gamma correction
    gammaCorrect = @(c) (c > 0.0031308) .* (1.055 * (c .^ (1 / 2.4)) - 0.055) + (c <= 0.0031308) .* (12.92 * c);
    r = gammaCorrect(r);
    g = gammaCorrect(g);
    b = gammaCorrect(b);
    
    % Clip the values to [0, 1]
    clip = @(c) max(min(c, 1), 0);
    r = clip(r);
    g = clip(g);
    b = clip(b);
    
    % Convert to 0-255 range
    r = r * 255;
    g = g * 255;
    b = b * 255;
    
    % Reshape the results back to the original image size
    r = reshape(r, [rows, cols]);
    g = reshape(g, [rows, cols]);
    b = reshape(b, [rows, cols]);
    r = uint8(r);
    g = uint8(g);
    b = uint8(b);
end
