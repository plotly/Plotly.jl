function get_points(f::Function, options=Dict())
	default = ["left"=>-10, "right"=>10, "step"=>0.5, "name"=>"$f", "type"=>"scatter", "mode"=>"lines"]
	opt = merge(default, options)
	n::Int = (opt["right"] - opt["left"]) / opt["step"] + 1
	X = Float64[0 for i in 1:n]
	Y = Float64[0 for i in 1:n]
	for i in 1:n
		x = opt["step"]*(i-1) + opt["left"]
		y = f(x)
		X[i] = round(x, 8)
		Y[i] = round(y, 8)
	end

	if opt["type"] == "histogram"
		return ["x"=>Y, "type"=>opt["type"], "mode"=>opt["mode"], "name"=>opt["name"]]
	elseif opt["type"] == "box"
		return ["y"=>Y, "type"=>opt["type"], "mode"=>opt["mode"], "name"=>opt["name"]]
	else
		return ["x"=>X, "y"=>Y, "type"=>opt["type"], "mode"=>opt["mode"], "name"=>opt["name"]]
	end
end

scatter(f::Function, options=Dict())        = get_points(f, merge(["type"=>"scatter", "mode"=>"markers"], options))
line(f::Function, options=Dict())           = get_points(f, merge(["type"=>"scatter", "mode"=>"lines"], options))
box(f::Function, options=Dict())            = get_points(f, merge(["type"=>"box"], options))
histogram(f::Function, options=Dict())      = get_points(f, merge(["type"=>"histogram"], options))
plot(f::Function, options=Dict())           = plot([line(f, options)])
plot(fs::Array{Function,1}, options=Dict()) = plot([lines(fs, options)])

if Pkg.installed("Polynomial") !== nothing
	import Polynomial: Poly, polyval

	scatter(p::Poly, options=Dict())   = scatter(x->polyval(p,x), options)
	line(p::Poly, options=Dict())      = line(x->polyval(p,x), options)
	box(p::Poly, options=Dict())       = box(x->polyval(p,x), options)
	histogram(p::Poly, options=Dict()) = histogram(x->polyval(p,x), options)

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

	scatter(ts::TimeArray, options=Dict()) = [
		["x"=>map(t->"$t", timestamp(ts[col])), "y"=>values(ts[col]), "type"=>"scatter", "mode"=>"markers", "name"=>col]
		for col in colnames(ts)
	]

	line(ts::TimeArray, options=Dict())      = [merge(x,["type"=>"line","mode"=>"lines"]) for x in scatter(ts)]
	box(ts::TimeArray, options=Dict())       = [merge(x,["type"=>"box"]) for x in scatter(ts)]
	histogram(ts::TimeArray, options=Dict()) = [merge(x,["type"=>"histogram"]) for x in scatter(ts)]
	plot(ts::TimeArray, options=Dict())      = plot([line(ts)], options)
end

if Pkg.installed("WAV") !== nothing
	function line{T<:Number,U<:Number,V<:Number}(wav::(Array{T,2},U,V,UnionType), options=Dict())
		w, Fs = wav
		X = [f/Fs for f in 1.0:length(w)]
		Y = [round(y,8) for y in w]
		["x"=>X, "y"=>Y, "type"=>"scatter", "mode"=>"lines", "name"=>"WAV data"]
	end

	scatter{T<:Number,U<:Number,V<:Number}(wav::(Array{T,2},U,V,UnionType), options=Dict())   = merge(line(wav),["type"=>"scatter","mode"=>"markers"])
	box{T<:Number,U<:Number,V<:Number}(wav::(Array{T,2},U,V,UnionType), options=Dict())       = merge(line(wav),["type"=>"box"])
	histogram{T<:Number,U<:Number,V<:Number}(wav::(Array{T,2},U,V,UnionType), options=Dict()) = merge(line(wav),["type"=>"histogram"])

	function plot{T<:Number,U<:Number,V<:Number}(wav::(Array{T,2},U,V,UnionType), options=Dict())
		opt = merge(["layout"=>["xaxis"=>["title"=>"seconds","dtick"=>1,"tick0"=>0,"autotick"=>false]]], options)
		return plot([line(wav)], opt)
	end
end

if Pkg.installed("DataFrames") !== nothing
	import DataFrames: DataFrame

	# plot((df, [:y1, :y2, ...])) --> box plots
	function plot(dfys::(DataFrame,Array{Symbol,1}), options=Dict())
		df, ys = dfys
		data = [["y"=>df[y], "type"=>"box", "name"=>"$y"] for y in ys]
		return plot([data], options)
	end

	# plot((df, :x)) --> histogram
	function plot(dfx::(DataFrame,Symbol), options=Dict())
		df, x = dfx
		data = [["x"=>df[x], "type"=>"histogram", "name"=>"$x"]]
		return plot([data], options)
	end

	# plot((df, :x, [:y1, :y2, ...])) --> scatter plots
	function plot(dfxys::(DataFrame,Symbol,Array{Symbol,1}), options=Dict())
		df, x, ys = dfxys
		X = df[x]
		data = [["x"=>X, "y"=>df[y], "type"=>"scatter", "mode"=>"markers", "name"=>"$y"] for y in ys]
		return plot([data], options)
	end

	# plot((df, :x, :y)) --> scatter plot
	function plot(dfxy::(DataFrame,Symbol,Symbol), options=Dict())
		df, x, y = dfxy
		return plot((df, x, [y]), options)
	end

	# Sane, Generic DataFrame plot
	function plot(df::DataFrame, options=Dict())
		if haskey(options, "xs") && haskey(options, "ys")
			return plot((df, options["xs"], options["ys"]))
		elseif haskey(options, "xs")
			return plot((df, options["xs"]))
		elseif haskey(options, "ys")
			return plot((df, options["ys"]))
		else
			return ["error"=>"Please set the xs and/or ys options."]
		end
	end
end