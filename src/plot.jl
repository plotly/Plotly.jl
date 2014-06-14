function get_points(f::Function, options=Dict())
	opt = merge(["left"=>-10, "right"=>10, "step"=>0.5, "name"=>"$f"], options)
	n::Int = (opt["right"] - opt["left"]) / opt["step"] + 1
	X = Float64[0 for i in 1:n]
	Y = Float64[0 for i in 1:n]
	for i in 1:n
		x = opt["step"]*(i-1) + opt["left"]
		y = f(x)
		X[i] = round(x, 8)
		Y[i] = round(y, 8)
	end

	return ["x"=>X, "y"=>Y, "type"=>"scatter", "name"=>opt["name"]]
end

function plot(fs::Array{Function,1}, options=Dict())
	data = [get_points(f, options) for f in fs]
	return plot([data], options)
end

function plot(f::Function, options=Dict())
	return plot([f], options)
end

if Pkg.installed("Polynomial") !== nothing
	import Polynomial: Poly, polyval

	function plot{T<:Number}(ps::Array{Poly{T},1}, options=Dict())
		data = [get_points(x->polyval(p,x), merge(["name"=>"$p"], options)) for p in ps]
		return plot([data], options)
	end

	function plot(p::Poly, options=Dict())
		return plot([p], options)
	end
end

if Pkg.installed("TimeSeries") !== nothing
	import TimeSeries: TimeArray, timestamp, values, colnames

	function plot(ts::TimeArray, options=Dict())
		data = [
			["x"=>map(t->"$t", timestamp(ts[col])), "y"=>values(ts[col]), "type"=>"scatter", "name"=>col]
			for col in colnames(ts)
		]
		return plot([data], options)
	end
end

if Pkg.installed("WAV") !== nothing
	function plot{T<:Number,U<:Number,V<:Number}(wav::(Array{T,2},U,V,UnionType), options=Dict())
		opt = merge(["layout"=>["xaxis"=>["title"=>"seconds","dtick"=>1,"tick0"=>0,"autotick"=>false]]], options)
		w, Fs = wav
		X = [f/Fs for f in 1.0:length(w)]
		Y = [round(y,8) for y in w]
		data = [["x"=>X, "y"=>Y, "type"=>"scatter", "mode"=>"lines", "name"=>"WAV data"]]
		return plot([data], opt)
	end
end

if Pkg.installed("DataFrames") !== nothing
	import DataFrames: DataFrame

	function plot(dfxs::(DataFrame,Array{Symbol,1}), options=Dict())
		df, xs = dfxs
		data = [["x"=>df[x], "type"=>"histogram", "opacity"=>0.75, "name"=>"$x"] for x in xs]
		return plot([data], options)
	end

	function plot(dfx::(DataFrame,Symbol), options=Dict())
		df, x = dfx
		return plot((df, [x]), options)
	end

	function plot(dfxys::(DataFrame,Symbol,Array{Symbol,1}), options=Dict())
		df, x, ys = dfxys
		X = df[x]
		data = [["x"=>X, "y"=>df[y], "type"=>"scatter", "mode"=>"markers", "name"=>"$y"] for y in ys]
		return plot([data], options)
	end

	function plot(dfxy::(DataFrame,Symbol,Symbol), options=Dict())
		df, x, y = dfxy
		return plot((df, x, [y]), options)
	end
end