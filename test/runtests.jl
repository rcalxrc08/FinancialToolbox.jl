my_tests = ["test1.jl"]

println("Running tests:")
i=1;
for my_test in my_tests
    println("  * $(my_test) *")
    include(my_test)
	if (i<length(my_tests))
		println("\n\n")
	end
end