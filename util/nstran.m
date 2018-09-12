function y = nstran(x, a, b, c)
% non stationary transformation

%y = 2*c*(-0.5+sigmf(x,[a b]));

y = 2*c*(-0.5+1./(1+exp(-a*(x-b))));
