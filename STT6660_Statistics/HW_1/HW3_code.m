k=2;
n=3;

bc = factorial(n)/(factorial(k)*factorial(n-k));

x = fsolve(@(x)0.10 - bc*x.^k.*(1-x).^(n-k), [0, 0.5, 1]);