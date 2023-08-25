## Bench pricer function
using FinancialToolbox, BenchmarkTools, ForwardDiff, ReverseDiff, Zygote, Yota

S0 = 100.0;
K = 100.0;
r = 0.01;
T = 1.0;
sigma = 0.2;
d = 0.01;
const inputs = [S0, K, r, T, sigma, d];
suite = BenchmarkGroup()
suite["standard evaluation"] = @benchmarkable blsprice(S0, K, r, T, sigma, d);

output = similar(inputs);
suite["forwarddiff evaluation"] = @benchmarkable @views ForwardDiff.gradient!(output, x -> blsprice(x[1], x[2], x[3], x[4], x[5], x[6]), $inputs);

suite["reversediff evaluation"] = @benchmarkable @views ReverseDiff.gradient(x -> blsprice(x[1], x[2], x[3], x[4], x[5], x[6]), $inputs);
cfg = ReverseDiff.GradientConfig(similar(inputs))
const f_tape = ReverseDiff.compile(ReverseDiff.GradientTape(x -> blsprice(x[1], x[2], x[3], x[4], x[5], x[6]), inputs, cfg))
suite["reversediff evaluation compiled"] = @benchmarkable ReverseDiff.gradient!($output, $f_tape, $inputs);
# suite["implied volatility forward"] = @benchmarkable ReverseDiff.gradient(x->blsprice(x...),inputs);

# suite["implied volatility forward"] = @benchmarkable @views Zygote.gradient(x -> blsprice(x[1], x[2], x[3], x[4], x[5], x[6]), inputs);
suite["zygote evaluation"] = @benchmarkable Zygote.gradient(blsprice, $S0, $K, $r, $T, $sigma, $d);
# suite["implied volatility forward"] = @benchmarkable Zygote.gradient(x->blsprice(x...),inputs);
@show run(suite)