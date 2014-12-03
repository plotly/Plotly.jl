function get_points(f::Function, options=Dict())
	default = {"left"=>-10, "right"=>10, "step"=>0.5, "name"=>"$f", "type"=>"scatter", "mode"=>"lines"}
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
		return {"x"=>Y, "type"=>opt["type"], "mode"=>opt["mode"], "name"=>opt["name"]}
	elseif opt["type"] == "box"
		return {"y"=>Y, "type"=>opt["type"], "mode"=>opt["mode"], "name"=>opt["name"]}
	else
		return {"x"=>X, "y"=>Y, "type"=>opt["type"], "mode"=>opt["mode"], "name"=>opt["name"]}
	end
end

scatter(f::Array, options=Dict())        = merge({"type"=>"scatter","mode"=>"markers", "x"=>[1:length(f)], "y"=>f}, options)
line(f::Array, options=Dict())           = merge({"type"=>"scatter","mode"=>"lines", "x"=>[1:length(f)], "y"=>f}, options)
box(f::Array, options=Dict())            = merge({"type"=>"box", "x"=>[1:length(f)], "y"=>f}, options)
histogram(f::Array, options=Dict())      = merge({"type"=>"histogram", "y"=>[1:length(f)], "x"=>f}, options)
bar(f::Array, options=Dict())            = merge({"type"=>"bar", "x"=>[1:length(f)], "y"=>f}, options)

scatter(f::Dict, options=Dict())        = merge({"type"=>"scatter","mode"=>"markers", "x"=>[k for k in sort(collect(keys(f)))], "y"=>[f[k] for k in sort(collect(keys(f)))]}, options)
line(f::Dict, options=Dict())           = merge({"type"=>"scatter","mode"=>"lines", "x"=>[k for k in sort(collect(keys(f)))], "y"=>[f[k] for k in sort(collect(keys(f)))]}, options)
box(f::Dict, options=Dict())            = merge({"type"=>"box", "x"=>[k for k in sort(collect(keys(f)))], "y"=>[f[k] for k in sort(collect(keys(f)))]}, options)
histogram(f::Dict, options=Dict())      = merge({"type"=>"histogram", "x"=>[k for k in sort(collect(keys(f)))], "y"=>[f[k] for k in sort(collect(keys(f)))]}, options)
bar(f::Dict, options=Dict())            = merge({"type"=>"bar", "x"=>[k for k in sort(collect(keys(f)))], "y"=>[f[k] for k in sort(collect(keys(f)))]}, options)

scatter(f::Function, options=Dict())        = get_points(f, merge({"type"=>"scatter","mode"=>"markers"}, options))
line(f::Function, options=Dict())           = get_points(f, merge({"type"=>"scatter","mode"=>"lines"}, options))
box(f::Function, options=Dict())            = get_points(f, merge({"type"=>"box"}, options))
histogram(f::Function, options=Dict())      = get_points(f, merge({"type"=>"histogram"}, options))
bar(f::Function, options=Dict())            = get_points(f, merge({"type"=>"bar"}, options))

plot(f::Function, options=Dict())           = plot([line(f, options)])
plot(fs::Array{Function,1}, options=Dict()) = plot([line(f, options) for f in fs])

if Pkg.installed("Polynomial") !== nothing
	import Polynomial: Poly, polyval

	scatter(p::Poly, options=Dict())   = scatter(x->polyval(p,x), options)
	line(p::Poly, options=Dict())      = line(x->polyval(p,x), options)
	box(p::Poly, options=Dict())       = box(x->polyval(p,x), options)
	histogram(p::Poly, options=Dict()) = histogram(x->polyval(p,x), options)
	bar(p::Poly, options=Dict())       = bar(x->polyval(p,x), options)

	function plot{T<:Number}(ps::Array{Poly{T},1}, options=Dict())
		data = [get_points(x->polyval(p,x), merge({"name"=>"$p"}, options)) for p in ps]
		return plot([data], options)
	end

	function plot(p::Poly, options=Dict())
		return plot([p], options)
	end
end

if Pkg.installed("TimeSeries") !== nothing
	import TimeSeries: TimeArray, timestamp, values, colnames

	scatter(ts::TimeArray, options=Dict()) = [
		{"x"=>map(t->"$t", timestamp(ts[col])), "y"=>values(ts[col]), "type"=>"scatter", "mode"=>"markers", "name"=>col}
		for col in colnames(ts)
	]

	line(ts::TimeArray, options=Dict())      = [merge(x,{"type"=>"line","mode"=>"lines"}) for x in scatter(ts)]
	box(ts::TimeArray, options=Dict())       = [merge(x,{"type"=>"box"}) for x in scatter(ts)]
	histogram(ts::TimeArray, options=Dict()) = [merge(x,{"type"=>"histogram"}) for x in scatter(ts)]
	bar(ts::TimeArray, options=Dict())       = [merge(x,{"type"=>"bar"}) for x in scatter(ts)]
	plot(ts::TimeArray, options=Dict())      = plot([line(ts)], options)
end

if Pkg.installed("WAV") !== nothing
	function line{T<:Number,U<:Number,V<:Number}(wav::(Array{T,2},U,V,UnionType), options=Dict())
		w, Fs = wav
		X = [f/Fs for f in 1.0:length(w)]
		Y = [round(y,8) for y in w]
		return {"x"=>X, "y"=>Y, "type"=>"scatter", "mode"=>"lines", "name"=>"WAV data"}
	end

	scatter{T<:Number,U<:Number,V<:Number}(wav::(Array{T,2},U,V,UnionType), options=Dict())   = merge(line(wav),{"type"=>"scatter","mode"=>"markers"})
	box{T<:Number,U<:Number,V<:Number}(wav::(Array{T,2},U,V,UnionType), options=Dict())       = merge(line(wav),{"type"=>"box"})
	histogram{T<:Number,U<:Number,V<:Number}(wav::(Array{T,2},U,V,UnionType), options=Dict()) = merge(line(wav),{"type"=>"histogram"})
	bar{T<:Number,U<:Number,V<:Number}(wav::(Array{T,2},U,V,UnionType), options=Dict())       = merge(line(wav),{"type"=>"bar"})

	function plot{T<:Number,U<:Number,V<:Number}(wav::(Array{T,2},U,V,UnionType), options=Dict())
		opt = merge({"layout"=>{"xaxis"=>{"title"=>"seconds","dtick"=>1,"tick0"=>0,"autotick"=>false}}}, options)
		return plot([line(wav)], opt)
	end
end

if Pkg.installed("DataFrames") !== nothing
	import DataFrames: DataFrame

	scatter(df::DataFrame, options=Dict())   = get_points(df, merge({"type"=>"scatter","mode"=>"markers"}, options))
	line(df::DataFrame, options=Dict())      = get_points(df, merge({"type"=>"scatter","mode"=>"lines"}, options))
	box(df::DataFrame, options=Dict())       = get_points(df, merge({"type"=>"box"}, options))
	histogram(df::DataFrame, options=Dict()) = get_points(df, merge({"type"=>"histogram"}, options))
	bar(df::DataFrame, options=Dict())       = get_points(df, merge({"type"=>"bar"}, options))
	function get_points(df::DataFrame, options=Dict())
		default = {"type"=>"scatter", "mode"=>"lines"}
		opt = merge(default, options)
		for axis in ["xs", "ys"]
			if  haskey(opt, axis) && typeof(opt[axis]) <: Symbol
				opt[axis] = [opt[axis]]
			end
		end

		if haskey(opt, "xs") && haskey(opt, "ys")
			if length(opt["xs"]) == length(opt["ys"])
				return [
					{"x"=>df[opt["xs"][i]], "y"=>df[opt["ys"][i]], "type"=>opt["type"], "mode"=>opt["mode"]}
					for i in 1:length(opt["xs"])
				]
			else
				return [
					{"x"=>df[x], "y"=>df[y], "type"=>opt["type"], "mode"=>opt["mode"]}
					for x in opt["xs"], y in opt["ys"]
				]
			end
		elseif haskey(opt, "xs")
			return [
				{"x"=>df[x], "type"=>opt["type"], "mode"=>opt["mode"]}
				for x in opt["xs"]
			]
		elseif haskey(opt, "ys")
			return [
				{"y"=>df[y], "type"=>opt["type"], "mode"=>opt["mode"]}
				for y in opt["ys"]
			]
		else
			return {"error"=>"Please set the xs and/or ys options."}
		end
	end

	function plot(df::DataFrame, options=Dict())
		if haskey(options, "xs") && haskey(options, "ys")
			return plot([scatter(df)], options)
		elseif haskey(options, "xs")
			return plot([histogram(df)], options)
		elseif haskey(options, "ys")
			return plot([box(df)], options)
		else
			return {"error"=>"Please set the xs and/or ys options."}
		end
	end
end