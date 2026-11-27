module FinancialToolboxReactantExt

using Reactant: TracedRNumber
import FinancialToolbox: domain_value

# Traced numbers have no value while Reactant traces a function: a check on them would be a branch on a traced value,
# which XLA cannot compile. They are not checked, like the symbolic values (the concrete arguments still are).
domain_value(::TracedRNumber) = nothing

end
