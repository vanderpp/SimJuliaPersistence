include("./SimJulia/SimJulia.jl")
#include("ResumableFunctions.jl")

##################################################################
#
#   This one is about manual chaining of events
#
###################################################################

ENV["JULIA_DEBUG"] = "none"

using .SimJulia, ResumableFunctions, DataStructures

#the goal is now to chain the events through the callback function.

function printlnCallback(ev::Event)
    #   function that does nothing. It is merely applied when the event is "called, executed, takes place..."
    println("Showing the application of a callback function here...")
    println(ev.bev.value)
    println(now(sim))
end

function throwStopException(ev::Event)
    println("This is the callback function: Preparing to throw an exception")
    stop_exception = StopSimulation("een stop exception")
    throw(stop_exception)
end

function chain(ev1,ev2, val::Any=nothing)
    succeed(ev2, value=val)
end

function createTimeOut(ev::Event)
    timeout(sim, 5)
end

sim = Simulation()

first_event = Event(sim)
@callback printlnCallback(first_event)          # adding some function to the callback of the first_event 
succeed(first_event, value="first event value") # Putting the first element on the heap                                       
                                                # at this time there is only one event on the heap, will be executed on t=0
                                                # you can check this through sim.heap

second_event = Event(sim)
@callback printlnCallback(second_event)
# After this, there lives a second event in the global context. It has one callback but is not on the heap

@callback chain(first_event,second_event, "second event value")
# this adds a second callback function to the vector of callbacks of the first event. 
# The first argument is the first event we will assign the callback to. The macro @callback requires this.
# The second argument is the event we want to put on the heap. It will happen at the same time of event1 because no timeout was between them.
# So when the 2nd callback of the first event is executed it will put the second event on the heap.

third_event = Event(sim)
@callback printlnCallback(third_event)

@callback chain(second_event,third_event, "third event value")
#these three repeat the effect we had between ev1 and ev2 but now for ev2 and ev3



@callback createTimeOut(third_event)

tmo = timeout(sim, 5) # A timeout is immediately scheduled (in the heap)

#@callback chain(tmo, third_event, "third event value, preparing for stopexception")

#@callback throwStopException(third_event)

#SimJulia.step(sim)