export to_kernel

function to_kernel(exprs...; save = [], explparams = ExplicitParam(), verbose=false)
	#Transforming the Forms expression into an Expression on arrays (TODO probably a more elegant way to do this)
	math_exprs = []
	for expr in exprs
		expl_expr = explicit(expr; param = explparams)
		if expl_expr isa AbstractArray
			math_exprs = vcat(math_exprs, expl_expr)
		else
			push!(math_exprs, expl_expr)
		end
	end
	
	if verbose
		println("Developped expression :")
		println(string(exprs))
	end


	#Transforming our Expression into a dependency tree
	tree = Arrays.to_deptree!(Set{String}(save), math_exprs)
	
	if verbose
		println("Tree view :")
		println(string(tree))

		println("Graphviz view of tree:")
		println(Arrays.to_graphviz(tree))
	end


	#Transforming our dependency tree into a sequence of expressions to compute
	seq = Arrays.to_sequence!(tree)

	if verbose
		println("Corresponding Sequence :")
		println(string(seq)*"\n")
	end


	#Generating the final function
	func!, funcstr, vars = Arrays.to_kernel(seq)
	
	if verbose
		println("Generated code :")
		println(funcstr)
	end

	function func_call!(mesh, state; var_repls = Dict{String, String}())
		kwargs = []

		for var in vars
			if var in keys(var_repls)
				push!(kwargs, Pair(Symbol(var), getproperty(state, Symbol(var_repls[var]))))
			else
				push!(kwargs, Pair(Symbol(var), getproperty(state, Symbol(var))))
			end
		end
		
		func!(mesh; kwargs...)
	end

	return func_call!
end
