include("./SimProbe/ProbeApp/CreateConfig.jl")
using .CreateConfig

dict1=Dict{Symbol, Any}(:sim => :Environment, :tripduration => Float64, :waitduration => Float64, :parkingduration => Float64)
dict2=Dict{Symbol, Any}(:sim => :Environment, :trafficlightwaittime => Float64)

saveSlotsToDb(:car,dict1)
saveSlotsToDb(:trafficlight,dict2)