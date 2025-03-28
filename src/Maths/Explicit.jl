import ..Arrays
export explicit, ExplicitParam

struct ExplicitParam
	interp

	function ExplicitParam(;interp = Arrays.upwind)
		return new(interp)
	end
end


#Vectors
function explicit(vect::VectorVariable{P}; param = ExplicitParam()) where {P}
	return [Arrays.ArrayVariable(vect.name*"_X"), Arrays.ArrayVariable(vect.name*"_Y")]
end

#FormVariables
function explicit(form::FormVariable{0, P}; param = ExplicitParam()) where {P}
	return Arrays.ArrayVariable(form.name)
end

function explicit(form::FormVariable{1, P}; param = ExplicitParam()) where {P}
	return [Arrays.ArrayVariable(form.name*"_x"), Arrays.ArrayVariable(form.name*"_y")]
end

function explicit(form::FormVariable{2,P}; param = ExplicitParam()) where {P}
	return Arrays.ArrayVariable(form.name)
end

#Addition
function explicit(form::Addition{0,P}; param = ExplicitParam()) where {P}
	return Arrays.Addition(form.name, explicit(form.left), explicit(form.right))
end

function explicit(form::Addition{1,P}; param = ExplicitParam()) where {P}
	ls = explicit(form.left)
	rs = explicit(form.right)

	return [Arrays.Addition(form.name*"_x", ls[1], rs[1]), Arrays.Addition(form.name*"_y", ls[2], rs[2])]
end

function explicit(form::Addition{2,P}; param = ExplicitParam()) where {P}
	return Arrays.Addition(form.name, explicit(form.left; param = param), explicit(form.right; param = param))
end

#Substraction
function explicit(form::Substraction{0,P}; param = ExplicitParam()) where {P}
	return Arrays.Addition(form.name, explicit(form.left; param = param), explicit(form.right; param = param))
end

function explicit(form::Substraction{1,P}; param = ExplicitParam()) where {P}
	ls = explicit(form.left; param = param)
	rs = explicit(form.right; param = param)

	return [Arrays.Substraction(form.name*"_x", ls[1], rs[1]), Arrays.Substraction(form.name*"_y", ls[2], rs[2])]
end

function explicit(form::Substraction{2,P}; param = ExplicitParam()) where {P}
	return Arrays.Substraction(form.name, explicit(form.left; param = param), explicit(form.right; param = param))
end

#Negative
function explicit(form::Negative{0,P}; param = ExplicitParam()) where {P}
	return Arrays.Negative(form.name, explicit(form.form; param = param))
end

function explicit(form::Negative{1,P}; param = ExplicitParam()) where {P}
	fexpr = explicit(form.form; param = param)
	return [Arrays.Negative(form.name*"_x", fexpr[1]), Arrays.Negative(form.name*"_y", fexpr[2])]
end

function explicit(form::Negative{2,P}; param = ExplicitParam()) where {P}
	return Arrays.Negative(form.name, explicit(form.form; param = param))
end

#Division
function explicit(form::Division{2,Dual}; param = ExplicitParam())
	left = explicit(form.left; param = param)
	right = explicit(form.right; param = param)

	res = left / Arrays.avg4pt(right, -1, -1) * Arrays.msk2d
	res.name = form.name

	return res
end

#RealProducts
function explicit(form::RealProdForm{0,D}; param = ExplicitParam()) where {D}
	res = form.real * explicit(form.form; param = param)
	res.name = form.name

	return res
end

function explicit(form::RealProdForm{1,D}; param = ExplicitParam()) where {D}
	exprs = explicit(form.form; param = param)

	l = form.real * exprs[1]
	r = form.real * exprs[2]

	l.name = form.name*"_x"
	r.name = form.name*"_y"

	return [l, r]
end

function explicit(form::RealProdForm{2,D}; param = ExplicitParam()) where {D}
	res = form.real * explicit(form.form; param = param)
	res.name = form.name

	return res
end

#ExteriorDerivative
function explicit(form::ExteriorDerivative{1, Primal}; param = ExplicitParam())
	expr = explicit(form.form; param = param)
	d_x = (expr[1,0] - expr[0,0]) * Arrays.msk1px
	d_x.name = form.name * "_x"

	d_y = (expr[0,1] - expr[0,0]) * Arrays.msk1py
	d_y.name = form.name * "_y"

	return [d_x, d_y]
end

function explicit(form::ExteriorDerivative{1, Dual}; param = ExplicitParam())
	expr = explicit(form.form; param = param)
	d_x = (expr[0,0] - expr[-1,0]) * Arrays.msk1dx
	d_x.name = form.name * "_x"

	d_y = (expr[0,0] - expr[0,-1]) * Arrays.msk1dy
	d_y.name = form.name * "_y"

	return [d_x, d_y]
end

function explicit(form::ExteriorDerivative{2, Primal}; param = ExplicitParam())
	exprs = explicit(form.form; param = param)
	dq = ((exprs[2][1,0]-exprs[2][0,0])-(exprs[1][0,1]-exprs[1][0,0])) * Arrays.msk2p
	dq.name = form.name

	return dq
end

function explicit(form::ExteriorDerivative{2, Dual}; param = ExplicitParam())
	exprs = explicit(form.form; param = param)
	dq = ((exprs[2][0,0]-exprs[2][-1,0])-(exprs[1][0,0]-exprs[1][0,-1])) * Arrays.msk2d
	dq.name = form.name

	return dq
end

#Codifferential TODO check sign
function explicit(form::Codifferential{0, Dual}; param = ExplicitParam())
	exprs = explicit(form.form; param = param)
	
	dq = -((exprs[1][1,0]-exprs[1][0,0]) + (exprs[2][0,1]-exprs[2][0,0])) * Arrays.msk0d
	dq.name = form.name

	return dq
end

function explicit(form::Codifferential{1, Dual}; param = ExplicitParam())
	expr = explicit(form.form; param = param)

	du = (expr[0,1] - expr[0,0]) * Arrays.msk1dx
	dv = -(expr[1,0] - expr[0,0]) * Arrays.msk1dy

	du.name = form.name * "_x"
	dv.name = form.name * "_y"

	return[du, dv]
end

#InteriorProduct
function explicit(form::InteriorProduct{0, Dual, Dual}; param = ExplicitParam())
	fx, fy = explicit(form.form; param = param)
	U, V = explicit(form.vect; param = param)

	fu = fx * U
	fv = fy * V
	
	Uint = param.interp(U[0,0] + U[1,0], fu, Arrays.o1dx, "right", "x")
	Vint = param.interp(V[0,0] + V[0,1], fv, Arrays.o1dy, "right", "y")
	
	#elseif interp == "2ptavg"
	#	Uint = 0.5 * (fu[0,0] + fu[-1,0])
	#	Vint = 0.5 * (fv[0,0] + fv[0,-1])
	#end
	
	qout = (Uint + Vint) * Arrays.msk0d
	
	qout.name = form.name

	return qout
end

function explicit(form::InteriorProduct{1, Dual, Primal}; param = ExplicitParam()) 
	fexpr = explicit(form.form; param = param)
	uexpr, vexpr = explicit(form.vect; param = param)

	fintx = param.interp(uexpr, fexpr, Arrays.o1px, "left", "x")
	finty = param.interp(vexpr, fexpr, Arrays.o1py, "left", "y")
	
	#elseif interp == "2ptavg"
	#	fintx = 0.5 * (fexpr[0,0] + fexpr[-1,0])
	#	finty = 0.5 * (fexpr[0,0] + fexpr[0,-1])
	#end

	uout = -vexpr * finty * Arrays.msk1px
	vout = uexpr * fintx * Arrays.msk1py

	uout.name = form.name*"_x"
	vout.name = form.name*"_y"

	return [uout, vout]
end

function explicit(form::InteriorProduct{1, Dual, Dual}; param = ExplicitParam())
	fexpr = explicit(form.form; param = param)
	uexpr, vexpr = explicit(form.vect; param = param)

	udec = Arrays.avg4pt(uexpr, 1, -1)
	vdec = Arrays.avg4pt(vexpr, -1, 1)

	#TODO transp velocity dec or not
	xout = -vdec * param.interp(vdec, fexpr, Arrays.o2dy, "right", "y") * Arrays.msk1dx
	yout = udec * param.interp(udec, fexpr, Arrays.o2dx, "right", "x") * Arrays.msk1dy
	
	#elseif interp == "2ptavg"
	#	xout = -vdec * 0.5 * (fexpr[0,0]+fexpr[0,1]) * Arrays.msk1dx
	#	yout = udec * 0.5 * (fexpr[0,0]+fexpr[1,0]) * Arrays.msk1dy
	#end

	return [xout, yout]
end

#Sharp
function explicit(vec::Sharp{D}; param = ExplicitParam()) where D #TODO separate Primal and dual areas (could be very different, especially for non square grids)
	xexpr, yexpr = explicit(vec.form; param = param)

	return [xexpr/Arrays.dx, yexpr/Arrays.dy]
end

#Hodge
function explicit(form::Hodge{0, Dual}; param = ExplicitParam())
	fexpr = explicit(form.form; param = param)

	return fexpr / Arrays.A
end

#InnerProduct
function explicit(form::InnerProduct{2, Primal}; param = ExplicitParam())
	ax, ay = explicit(form.left; param = param)
	bx, by = explicit(form.right; param = param)
	return 0.5*(ax*bx + ax[1,0]*bx[1,0] + ay*by + ay[0,1]*by[0,1]) * Arrays.msk2p
end

#InverseLaplacian
function explicit(form::InverseLaplacian{0, Dual}; param = ExplicitParam())
	fexpr = explicit(form.form; param = param)

	return Arrays.FuncCall(form.name, "Main.poisson_solver", [fexpr], 0, 0)
end

function explicit(form::InverseLaplacian{2, Dual}; param = ExplicitParam())
	fexpr = explicit(form.form; param = param)

	return Arrays.FuncCall(form.name, "Main.poisson_solver", [fexpr], 0, 0)
end
