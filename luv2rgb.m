function rgbmap = luv2rgb (luvmap)
%Author Hans Gao 
%INPUT = LUV DOUBLE image, 3 channels (L, u, v)
%OUTPUT = RGB UNIT8 image, 3 channels (R, G, B)

    [X, Y, Z] = luv2xyz(luvmap(:, :, 1), luvmap(:, :, 2), luvmap(:, :, 3));
    [R, G, B] = xyz2rgb(X, Y, Z);
    rgbmap = cat(3, R, G, B);
end