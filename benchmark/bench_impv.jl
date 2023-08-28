## Bench pricer function
using FinancialToolbox, BenchmarkTools, ForwardDiff, ReverseDiff, Zygote, TaylorSeries
suite = BenchmarkGroup()
S0 = 100.0;
K = 100.0;
r = 0.01;
T = 1.0;
sigma = 0.2;
d = 0.01;
price = blsprice(S0, K, r, T, sigma, d);
inputs = [S0, K, r, T, price, d];
output = similar(inputs);
suite["implied volatility"] = @benchmarkable blsimpv($S0, $K, $r, $T, $price, $d)
suite["implied volatility forward"] = @benchmarkable @views ForwardDiff.gradient!(output, x -> blsimpv(x[1], x[2], x[3], x[4], x[5], x[6]), $inputs);
suite["implied volatility ReverseDiff"] = @benchmarkable @views ReverseDiff.gradient(x -> blsimpv(x[1], x[2], x[3], x[4], x[5], x[6]), $inputs);
cfg = ReverseDiff.GradientConfig(similar(inputs))
f_tape = ReverseDiff.compile(ReverseDiff.GradientTape(x -> blsimpv(x[1], x[2], x[3], x[4], x[5], x[6]), inputs, cfg))
suite["implied volatility ReverseDiff compiled"] = @benchmarkable ReverseDiff.gradient!($output, $f_tape, $inputs);
suite["implied volatility Zygote"] = @benchmarkable Zygote.gradient(blsimpv, $S0, $K, $r, $T, $price, $d);

spot_taylor = taylor_expand(identity, S0, order = 22)
price_taylor = blsprice(spot_taylor, K, r, T, sigma, d);
suite["implied volatility taylor_series"] = @benchmarkable blsimpv($spot_taylor, $K, $r, $T, $price_taylor, $d);
tune!(suite)
@show run(suite)
