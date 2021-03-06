%%
% This code will supply the Z value given some probability

clear all
close all
clc

data = [2.3 2.6 2.4 2.2 2.3 2.5 1.9 2.2];

avg = mean(data)
stdev = std(data)

prob = .975;

Zt = tinv(prob, 7)

Probt = tcdf(1.323, 7)

Ylow = avg - Zt*(stdev/sqrt(7))
Yhigh = avg + Zt*(stdev/sqrt(7))