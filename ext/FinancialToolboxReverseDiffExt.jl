module FinancialToolboxReverseDiffExt

using ReverseDiff
using ReverseDiff: TrackedReal, SpecialInstruction, istracked, value, deriv, increment_deriv!, pull_value!, value!, unseed!
using FinancialToolbox
using FinancialToolbox: value_and_partials

# blsprice, blkprice, blsimpv and blkimpv are recorded on the tape as one instruction each,
# with their closed form partial derivatives, instead of the 10-30 scalar operations ReverseDiff would trace through
# them (about 50 ns each on a compiled tape).
# The instructions are written by hand rather than with ReverseDiff.@grad: a compiled tape reruns only the forward
# pass of an @grad function, which keeps the pullback of the point where the tape was recorded, so its gradients at
# any other point are wrong. The forward pass here stores the partials at the current point in the instruction.

# value_and_partials (src/financial_value_and_partials.jl): the value of f and its partials in closed form

# Records out = f(inputs...) on the tape of the tracked inputs, with the partials in the cache of the instruction
function record_instruction(f, inputs, parameters)
    out_value, partials = value_and_partials(f, map(value, inputs)..., parameters)
    tp = ReverseDiff.tape(inputs...)
    out = ReverseDiff.track(out_value, tp)
    ReverseDiff.record!(tp, SpecialInstruction, f, inputs, out, (Ref(partials), parameters))
    return out
end

const RECORDED = Union{typeof(blsprice), typeof(blkprice), typeof(blsimpv), typeof(blkimpv)}

refresh_value!(x::TrackedReal) = (pull_value!(x); nothing)
refresh_value!(_) = nothing
add_adjoint!(x::TrackedReal, adjoint) = (istracked(x) && increment_deriv!(x, adjoint); nothing)
add_adjoint!(_, _) = nothing

@noinline function ReverseDiff.special_forward_exec!(instruction::SpecialInstruction{<:RECORDED})
    foreach(refresh_value!, instruction.input)
    out_value, partials = value_and_partials(instruction.func, map(value, instruction.input)..., instruction.cache[2])
    instruction.cache[1][] = partials
    value!(instruction.output, out_value)
    return nothing
end

@noinline function ReverseDiff.special_reverse_exec!(instruction::SpecialInstruction{<:RECORDED})
    out_adjoint = deriv(instruction.output)
    foreach((x, partial) -> add_adjoint!(x, out_adjoint * partial), instruction.input, instruction.cache[1][])
    unseed!(instruction.output)
    return nothing
end

# Methods for every combination of tracked inputs (at least one): the other arguments are parameters
function tracked_methods(f, inputs, parameters)
    for tracked in Iterators.product(ntuple(_ -> (false, true), length(inputs))...)
        any(tracked) || continue
        args = [is_tracked ? :($x::TrackedReal) : x for (x, is_tracked) in zip(inputs, tracked)]
        parameter_names = [p.args[1] for p in parameters]
        @eval FinancialToolbox.$f($(args...), $(parameters...)) = record_instruction($f, ($(inputs...),), $(length(parameters) == 1 ? parameter_names[1] : :(($(parameter_names...),))))
    end
end
tracked_methods(:blsprice, (:S0, :K, :r, :T, :σ, :d), (:(FlagIsCall::Bool),))
tracked_methods(:blkprice, (:F0, :K, :r, :T, :σ), (:(FlagIsCall::Bool),))
tracked_methods(:blsimpv, (:S0, :K, :r, :T, :Price, :d), (:(FlagIsCall::Bool), :(xtol::Real), :(n_iter_max::Integer)))
tracked_methods(:blkimpv, (:F0, :K, :r, :T, :Price), (:(FlagIsCall::Bool), :(xtol::Real), :(n_iter_max::Integer)))

end
