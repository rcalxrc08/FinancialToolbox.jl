test_list = ["testRealNumbers.jl";"testComplexNumbers.jl";"testDualNumbers.jl";"testHyperDualNumbers.jl"]

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