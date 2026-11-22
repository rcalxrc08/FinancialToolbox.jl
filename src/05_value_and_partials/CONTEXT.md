# Stage 05: value and partials

The value and all the partials in closed form of `blsprice`, `blkprice`, `blsimpv` and `blkimpv`, and the ChainRules
rules of their broadcasts.

## Inputs

| Load | Why |
|:--|:--|
| `financial_value_and_partials.jl` | `value_and_partials(f, inputs..., parameters)`, `broadcast_value_and_partials`, `reduce_to_argument`, the broadcast `rrule`s |
| `references/autodiff.md` | why the broadcast rules exist (Zygote on GPU arrays) and how ReverseDiff uses them |
| `references/gpu.md` | the GPU constraints |

## Process

- One fused pass, partials as thunks, gradients reduced over the broadcast dimensions (`reduce_to_argument`).
- A new public function with a broadcast rule needs its partials here and a case in `test/ad/broadcast_rules.jl` (every
  argument, every broadcast shape).

## Outputs

`value_and_partials`, used by `ext/FinancialToolboxReverseDiffExt.jl` and by the broadcast `rrule`s. Checked by
`test/ad/broadcast_rules.jl` (against ForwardDiff), `test/ad/reversediff.jl`, `test/gpu/jlarrays.jl`.

## Verify (Kaimon)

| Check | Expect |
|:--|:--|
| `run_tests()` | `ad/broadcast_rules.jl` and `gpu/jlarrays.jl` pass |
