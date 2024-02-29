include("SimJulia.jl")
#include("ResumableFunctions.jl")

ENV["JULIA_DEBUG"] = "none"

using .SimJulia, ResumableFunctions, DataStructures

function test1()
    function printlnCallback(ev::Event)
        println("Showing the application of a callback function here...")
        println(ev.bev.value)
    end
    
    sim = Simulation()

    first_event = Event(sim)
    succeed(first_event, value="een custom event")

    the_timeout =  timeout(sim, 3, value="een test timeout") 
    #zonder callback heb je nu 2 events op de heap: een gewone event en een timeout. de timeout moet je niet succeeden, dat gebeurt sowieso na het verstrijken van de delay

    @callback printlnCallback(first_event)

    # hieronder het gedrag van run() -- zonder exception handling
    @callback stop_simulation(the_timeout) 
    #nu zet je als callback van de timeout de functie stop_simulation(<event>), die eigenlijk een exception throws als de event timeout geprocessed wordt.
    #de callback is in feite een functie die een exception throws
    
    
    SimJulia.step(sim)
    SimJulia.step(sim)
end

function test2()
    function throwStopException(ev::Event)
        println("This is the callback function: Preparing to throw an exception")
        stop_exception = StopSimulation("een stop exception")
        throw(stop_exception)
    end
    
    sim = Simulation()

    first_event = Event(sim)
    succeed(first_event, value="een custom event")
    
    TimeOutEvent = timeout(sim,2)

    second_event = Event(sim)

    third_event = second_event & TimeOutEvent
    # hier zou ik dus die tweede event willen schedulen op een bepaalde tijd.
    succeed(second_event)

    @callback throwStopException(third_event)
    
    println("Preparing First step")
    SimJulia.step(sim)
    println("Preparing Second step")
    SimJulia.step(sim)    
    println("Preparing Third step")
    SimJulia.step(sim)
    println("Ended")

    #SimJulia.step(sim)
end

function test3() #=  idem test2 maar met poging om de callback naar het derde event te verzetten ==> lukt niet (geprobeerd via:
                                                                                                                    1) scheduling
                                                                                                                    2) een timeout tussenin) =#
    function throwStopException(ev::Event)
        println("This is the callback function: Preparing to throw an exception")
        stop_exception = StopSimulation("een stop exception")
        throw(stop_exception)
    end

    function callbackTimeOut(ev1::Event, ev2::Event)
        succeed(ev2)
    end
    
    sim = Simulation()

    first_event = Event(sim)
    succeed(first_event, value="een custom event")

    tmo = timeout(sim, 5)

    second_event = Event(sim)

    @callback callbackTimeOut(tmo, second_event) 

    

    # hier zou ik dus die tweede event willen schedulen op een bepaalde tijd.
    

    @callback throwStopException(second_event)
    
    println("Preparing First step")
    SimJulia.step(sim)
    println("Preparing Second step")
    SimJulia.step(sim)    
    println("Preparing Third step")
    SimJulia.step(sim)
    println("Ended")


    #SimJulia.step(sim)
end

# function test4()
#     @resumable function car(sim::Environment)
#         #   parking sequence
#         println("Start parking at $(sim.time)")
#         parking_duration = 5.0
#         @yield timeout(sim, parking_duration)
        
#         #   driving sequence
#         println("Start driving at $(sim.time)")
#         trip_duration = 2.0
#         @yield timeout(sim, trip_duration)
#     end

#     #=
#     @resumable maakt drie dingen aan:
#         1)  een struct fsmi met identifier var"..." die de variabelen in de state machine bijhoudt en ook de state van deze state machine.
#             De struct heeft een constructor var"..."()
#         2)  een function met identifier en arg dezelfde al wat je aan @resumable doorgaf. 
#             Het is in feite de constructor van de struct voor een fsmi die toegankelijk wordt
#         3)  een functie die de de state machine zelf voorstelt.
#             Je hebt toegang tot de state machine door de functie-applicatie van de originele identifier met actueel argument een simulatie opnieu te callen.
#             Deze call voert de state macine uit tot aan de eerste return (een vertaling van een @yield)
#     =#
    
#     # sim = Simulation()

#     # @process car(sim)
#     # #=
#     # @process krijgt dus een state machine terug.

#     # maar @process zal zelf ook een event schedulen
    
#     # =#

#     # global heap = DataStructures.peek(sim.heap)

# end
#test1()

# @resumable function car(sim::Environment)
#     #   parking sequence
#     println("Start parking at $(sim.time)")
#     parking_duration = 5.0
#     @yield timeout(sim, parking_duration)
    
#     #   driving sequence
#     println("Start driving at $(sim.time)")
#     trip_duration = 2.0
#     @yield timeout(sim, trip_duration)
# end


#run(sim)
#step(sim)


# function step(sim::Simulation)
#     isempty(sim.heap) && throw(EmptySchedule())
#     (bev, key) = DataStructures.peek(sim.heap)
#     DataStructures.dequeue!(sim.heap)
#     sim.time = key.time
#     bev.state = processed
#     for callback in bev.callbacks
#       callback()
#     end
#   end

function test5()
    function printlnCallback(ev::Event)
        println("Showing the application of a callback function here...")
        println(ev.bev.value)
        println(now(sim))
    end
    
    sim = Simulation()
    
    #in the next sequence i show where the event gets put on the heap.
    println(sim.heap)
    first_event = Event(sim)
    
    println(sim.heap)
    @callback printlnCallback(first_event)
    
    println(sim.heap)
    succeed(first_event, value = "ev1") # after a succeed the event is put on the heap
    
    println(sim.heap)

    second_event = Event(sim)
    @callback printlnCallback(second_event)
    succeed(second_event, value="ev2")
    
    println(sim.heap)

    #this is how you terminate the simulation from the process itself: 
    #the stop_simulation is put as callback of an event and generates an exception which run(sim) catches to quit nicely.

    stopEvent = Event(sim)
    succeed(stopEvent, value="theEnd")
    @callback stop_simulation(stopEvent)

    run(sim)

    
end

function test6()
    #the goal is now to chain the events through the callback function
    # the simulation exits nicely through throwStopException(), however this function is in fact what stop_simulation does for you.

    function printlnCallback(ev::Event)
        println("Showing the application of a callback function here...")
        println(ev.bev.value)
        println(now(sim))
    end

    function throwStopException(ev::Event)
        println("This is the callback function: Preparing to throw an exception")
        stop_exception = StopSimulation("een stop exception") #stopSimulation() is a constructor
        throw(stop_exception)
        #this is the behaviour of the stop_simulation function inherently present in the framework. so 
    end

    function chain(ev1,ev2, val::Any=nothing)
        succeed(ev2, value=val)
    end
    
    sim = Simulation()
    
    first_event = Event(sim)
    @callback printlnCallback(first_event)
    
    second_event = Event(sim)
    @callback printlnCallback(second_event)
    @callback chain(first_event,second_event, "second event value")
    
    third_event = Event(sim)
    @callback printlnCallback(third_event)

    succeed(first_event, value="first event value") # Putting the first element on the heap
    
    tmo = timeout(sim, 5) # A timeout is immediately scheduled (in the heap)

    @callback chain(tmo, third_event, "third event value, preparing for stopexception")
    
    @callback throwStopException(third_event)

    return sim
end

function test7()
    function chain(ev1::Event, ev2::Event, val::Any=Nothing)
        succeed(ev2, value=val)
    end

    sim=Simulation()

    event1 = Event(sim)

    event2 = Event(sim)

    event3 = Event(sim)


    @callback chain(event1, event2)
    @callback chain(event2, event3)
    @callback stop_simulation(event3)
    
    
    succeed(event1,value="initial event")

    return sim
end