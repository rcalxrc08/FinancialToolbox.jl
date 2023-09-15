function print_colored(in::String, color1)
    if (VERSION.major == 0 && VERSION.minor <= 6)
        return print_with_color(color1, in)
    else
        return printstyled(in, color = color1)
    end
end

test_list = ["testRealNumbers.jl", "test_implied_volatility.jl", "test_implied_volatility_black.jl", "testComplexNumbers.jl", "testForwardDiff.jl", "testDual_.jl", "testHyperDualNumbers.jl", "testDates.jl", "testTaylor.jl", "testZygote.jl"]

println("Running tests:\n")
for (current_test, i) in zip(test_list, 1:length(test_list))
    println("------------------------------------------------------------")
    println("  * $(current_test) *")
    include(current_test)
    println("------------------------------------------------------------")
    if (i < length(test_list))
        println("")
    end
end