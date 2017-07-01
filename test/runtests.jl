my_tests = ["test1.jl"]

println("Running tests:")

for my_test in my_tests
    println("  * $(my_test) *")
    include(my_test)
    println("\n\n")
end