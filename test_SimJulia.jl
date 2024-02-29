include("./SimJulia/SimJulia.jl")
#include("ResumableFunctions.jl")

ENV["JULIA_DEBUG"] = "none"

using .SimJulia, ResumableFunctions, DataStructures

function cbFunc(ev::Event, msg::String)
    println("executed the callback function cbFunc: $(ev.bev.value) and $(msg) ")
end

function chain(evnt1, evnt2::Event,val)
    succeed(evnt2, value=val) #het is de value van ev2 die je gaat zetten.
end

sim = Simulation()

ev1 = Event(sim)
succeed(ev1, value="Event 1 scheduled at t0")
@callback cbFunc(ev1,"ev1 cb message")

ev2 = Event(sim)
SimJulia.schedule(ev2,10,value="Event 2 scheduled at t10")

tmo =  timeout(sim, 3, value="tmo scheduled at t3")

ev3 = Event(sim)
@callback chain(tmo,ev3,"Event 3 scheduled by chain after tmo")

@callback stop_simulation(ev3)  #deze functie gaat een exception throwen wanneer ze getriggerd wordt bij het uitvoeren van de CB's op ev2
                                #doe je se stepped, dan zie je de exception. doe je ze met run, dan wordt deze excepion opgevangen en stopt de sim nice

#   Running the simulation
function steppedRun(sim)
    println(collect(sim.heap))
    SimJulia.step(sim)
end


