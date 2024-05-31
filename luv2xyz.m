function [X, Y, Z] = luv2xyz(L, u, v)
% Author: Hans Gao
% Color conversion algorithm referencing https://www.easyrgb.com/en/math.php
%INPUT_FORMAT = DOUBLE
%OUTPUT_FORMAT = DOUBLE

    % Define the reference white values (D65 illuminant)
    ref_X = 95.047;
    ref_Y = 100.000;
    ref_Z = 108.883;

    % Calculate reference u' and v'
    ref_denom = ref_X + 15 * ref_Y + 3 * ref_Z;
    ref_U = (4 * ref_X) / ref_denom;
    ref_V = (9 * ref_Y) / ref_denom;

    % Calculate var_Y
    var_Y = (L + 16) / 116;
    threshold = 0.008856;
    var_Y = arrayfun(@(y) (y^3 > threshold) * y^3 + (y^3 <= threshold) * ((y - 16/116) / 7.787), var_Y);

    % Calculate var_U and var_V
    var_U = u ./ (13 * L) + ref_U;
    var_V = v ./ (13 * L) + ref_V;

    % Calculate Y
    Y = var_Y * 100;

    % Calculate X and Z
    denom = (var_U - 4) .* var_V - var_U .* var_V;
    X = -(9 * Y .* var_U) ./ denom;
    Z = (9 * Y - (15 * var_V .* Y) - (var_V .* X)) ./ (3 * var_V);

    % Reshape the results back to the original image size
    [rows, cols] = size(L);
    X = reshape(X, [rows, cols]);
    Y = reshape(Y, [rows, cols]);
    Z = reshape(Z, [rows, cols]);
end
