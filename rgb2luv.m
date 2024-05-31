function luvmap = rgb2luv (input_image)
%Author Hans Gao 
%INPUT = RGB UNIT8 image, 3 channels (R, G, B)
%OUTPUT = LUV DOUBLE image, 3 channels (L, u, v)

    [X, Y, Z] = rgb2xyz(input_image(:, :, 1), input_image(:, :, 2), input_image(:, :, 3));
    [L, u, v] = xyz2luv(X, Y, Z);
    luvmap = cat(3, L, u, v);
end