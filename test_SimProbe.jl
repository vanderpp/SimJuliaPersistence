include("./SimJulia/SimJulia.jl")

ENV["JULIA_DEBUG"] = "none"

using .SimJulia, ResumableFunctions, DataStructures

@resumable function car(sim::Environment)
    parkingduration=waitduration=tripduration=0.0
    #nonsensevar=2.0
        while true
            #   parking sequence
            #println("Start parking at $(sim.time)")
            parkingduration = 3.0
            @yield timeout(sim, parkingduration)

            #   waiting sequence
            #println("Start waiting at $(sim.time)")
            waitduration = 3.0
            @yield timeout(sim, waitduration)
            
            #   driving sequence
            #println("Start driving at $(sim.time)")
            tripduration = 6.0
            @yield timeout(sim, tripduration)
            
            @yield @process trafficlight(sim)
        end
end false

@resumable function trafficlight(sim::Environment)
    #println("Start waiting in front of trafficlight at $(sim.time)")
    trafficlightwaittime = 7.0
    @yield timeout(sim, trafficlightwaittime)
end false

# sim2 = Simulation()
# @process car(sim2)

#   remark: both modes remain possible
#   1. To run in the classic way: use the run function
#   2. To run in the persisted way, use the @runPersisted macro
#   both take the same arguments.

# for i in 1:20
#     sim2 = Simulation()
#     @process car(sim2)
#     #@time @runPersisted(sim2, 1000) 
#     @time run(sim2,1000)
# end 
#run(sim2,100)

sim2 = Simulation()
@process car(sim2)
@time @runPersisted(sim2, 1000) 

#@makeMonitored
#run(sim, 100, monitored=true)