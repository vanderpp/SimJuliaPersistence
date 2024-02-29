include("./SimJulia/SimJulia.jl")
#include("ResumableFunctions.jl")

ENV["JULIA_DEBUG"] = "all"

using .SimJulia 
using ResumableFunctions
using Distributions
const PT_MEAN = 10.0
const PT_SIGMA = 2.0

PD_dist=Normal(PT_MEAN, PT_SIGMA)

@resumable function car(sim::Environment)
                while true
                        #   parking sequence
                        println("Start parking at $(sim.time)")
                        parking_duration = trunc(rand(PD_dist))
                        @yield timeout(sim, parking_duration)
                        
                        #   driving sequence
                        println("Start driving at $(sim.time)")
                        trip_duration = 2.0
                        @yield timeout(sim, trip_duration)
                end 
        end

sim = Simulation()

@process car(sim)

#event=peek(sim.heap)
#cb=event.first.callbacks[1]