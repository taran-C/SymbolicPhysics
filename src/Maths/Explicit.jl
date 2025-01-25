import ..Arrays
export explicit

#0-Forms
function explicit(form::FormVariable{0, P}) where {P}
	return Arrays.ArrayVariable(form.name)
end

function explicit(form::Addition{0,P}) where {P}
	return Arrays.Addition(form.name, explicit(form.left), explicit(form.right))
end

function explicit(form::ExteriorDerivative{1, Primal})
	expr = explicit(form.form)

	return (Arrays.Substraction(form.name * "_x", expr[1,0], expr[0,0]), Arrays.Substraction(form.name*"_y", expr[0,1], expr[0,0]))
end

#1-Forms
function explicit(form::FormVariable{1, P}) where {P}
	return (Arrays.ArrayVariable(form.name*"_x"), Arrays.ArrayVariable(form.name*"_y"))
end

function explicit(form::Addition{1,P}) where {P}
	ls = explicit(form.left)
	rs = explicit(form.right)

	return (Arrays.Addition(form.name*"_x", ls[1], rs[1]), Arrays.Addition(form.name*"_y", ls[2], rs[2]))
end

function explicit(form::ExteriorDerivative{2, Primal})
	exprs = explicit(form.form)

	return Arrays.Substraction(form.name, exprs[2][1,0]-exprs[2][0,0], exprs[1][0,1]-exprs[1][0,0])
end

#2-Forms
function explicit(form::FormVariable{2,P}) where {P}
	return Arrays.ArrayVariable(form.name)
end
