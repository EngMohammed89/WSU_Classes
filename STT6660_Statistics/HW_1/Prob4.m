%%
% This code will supply the Z value given some probability

clear all
close all
clc

data = [2.3 2.6 2.4 2.2 2.3 2.5 1.9 2.2];

avg = mean(data)
stdev = std(data)

% range = linspace(0,350,200);
% 
% cdf_val = cdf(pd, range);
% pdf_val = pdf(pd, range);

% figure()
% plot(range, cdf_val)
% figure()
% plot(range, pdf_val)

prob = .95;

Zt = tinv(prob, 7)

Probt = tcdf(1.237, 7)

Ylow = avg - Zt*(stdev/sqrt(7))
Yhigh = avg + Zt*(stdev/sqrt(7))