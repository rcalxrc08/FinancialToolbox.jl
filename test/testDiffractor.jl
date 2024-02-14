using FinancialToolbox, Diffractor, AbstractDifferentiation
S0 = 100.0;
K = 100.0;
r = 0.02;
T = 1.0;
σ = 0.2;
d = 0.01;
price = blsprice(S0, K, r, T, σ, d);

price_grad = AbstractDifferentiation.gradient(Diffractor.DiffractorForwardBackend(), x -> blsprice(x...), [S0, K, r, T, σ, d])
price_grad_r = Diffractor.reversediff(x -> blsprice(x...), [S0, K, r, T, σ, d])
sigma_grad = AbstractDifferentiation.gradient(Diffractor.DiffractorForwardBackend(), x -> blsimpv(x...), [S0, K, r, T, price, d])
sigma_grad_r = Diffractor.reversediff(x -> blsimpv(x...), [S0, K, r, T, price, d])