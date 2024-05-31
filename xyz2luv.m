function [L, u, v] = xyz2luv(X, Y, Z)
% Author: Hans Gao
% Color conversion algorithm referencing https://www.easyrgb.com/en/math.php

%INPUT_FORMAT = DOUBLE
%OUTPUT_FORMAT = DOUBLE

    % Define the reference white values (D65 illuminant)
    %DAYLIGHT
    ref_X = 95.047;
    ref_Y = 100.000;
    ref_Z = 108.883;

    % Calculate u' and v' for the input XYZ values
    denom = X + 15 * Y + 3 * Z;
    var_U = (4 * X) ./ denom;
    var_V = (9 * Y) ./ denom;

    % Normalize Y
    var_Y = Y / 100;

    % Apply the transformation for var_Y
    threshold = 0.008856;
    var_Y = arrayfun(@(y) (y > threshold) * y^(1/3) + (y <= threshold) * ((7.787 * y) + (16 / 116)), var_Y);

    % Calculate reference u' and v'
    ref_denom = ref_X + 15 * ref_Y + 3 * ref_Z;
    ref_U = (4 * ref_X) / ref_denom;
    ref_V = (9 * ref_Y) / ref_denom;

    % Calculate L*, u*, and v*
    L = (116 * var_Y) - 16;
    u = 13 * L .* (var_U - ref_U);
    v = 13 * L .* (var_V - ref_V);

end
