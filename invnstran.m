function y = invnstran(x, a, b, c)
% inverse non stationary transformation

% ns transformation
% y = 2*c*(-0.5+1./(1+exp(-a*(x-b))));

y = b - 1/a*log(1./(x/2/c + 0.5) - 1);