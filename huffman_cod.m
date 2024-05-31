function [ comp, dict ] = huffman_cod( input_matrix)
% function computing huffman codes

%===================================
%Maybe we can reuse code from lab
%Maybe our code is more efficient
%===================================


%disassembles cells if the input is a cell array
%is there a better way to do it? might improve compression rate
if iscell(input_matrix)
    input_matrix = [input_matrix{:}];
end

%Change the implementation below
%================================================
symbols = unique(input_matrix);

L = length(symbols);
m = size(input_matrix, 1);
n = size(input_matrix, 2);
symbols = reshape(symbols, 1, L);
if length(symbols) < 2
    comp = 0;
    dict = [0 1];
    return;
end
probs = histc(input_matrix(:),symbols)./(m*n);
s = round(sum(probs)); % round to prevent an inequation 1 ~= 1.0000
if s ~= 1
    error('Error in prob_hist: probabilities do not sum to 1');
end

[dict, avglen] = huffmandict(symbols, probs);
comp = huffmanenco(input_matrix(:),dict);
end