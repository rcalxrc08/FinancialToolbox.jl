function print_colored(in::String,color1)
	if (VERSION.major==0&&VERSION.minor>6)
		return printstyled(in,color=color1)
	else
		return print_with_color(color1,in) 
	end
end



test_list = ["testRealNumbers.jl";"testComplexNumbers.jl";"testForwardDiff.jl";"testHyperDualNumbers.jl";"testDates.jl"]

println("Running tests:\n")
i=1;
for current_test in test_list
	println("------------------------------------------------------------")
    println("  * $(current_test) *")
    include(current_test)
	println("------------------------------------------------------------")
	if (i<length(test_list))
		println("")
	end
	i+=1;
end