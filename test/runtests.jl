my_tests = ["testRealNumbers.jl";"testComplexNumbers.jl";"testDualNumbers.jl";"testHyperDualNumbers.jl"]

println("Running tests:")
i=1;
for my_test in my_tests
    println("  * $(my_test) *")
    include(my_test)
	if (i<length(my_tests))
		println("")
	end
end