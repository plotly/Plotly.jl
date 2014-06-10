pkgs = keys(Pkg.installed())

if in("Polynomial", pkgs)
	using Polynomial
	function get_points(p::Poly, left, right, step)
		n::Int = (right - left) / step + 1
		X = Float64[0 for i in 1:n]
		Y = Float64[0 for i in 1:n]
		for i in 1:n
			x = step*(i-1) + left
			y = polyval(p, x)
			X[i] = x
			Y[i] = y
		end
		return ["x"=>X, "y"=>Y, "type"=>"scatter", "mode"=>"lines", "name"=>"$p"]
	end

	function plot{T<:Number}(ps::Array{Poly{T},1}, options=Dict())
		opt = merge(options, ["left"=>-10, "right"=>10, "step"=>0.5])
		data = [get_points(p, opt["left"], opt["right"], opt["step"]) for p in ps]
		return plot([data], options)
	end

	function plot(p::Poly, options=Dict())
		return plot([p], options)
	end
end