abstract type AbstractProcess <: AbstractEvent end
abstract type DiscreteProcess <: AbstractProcess end

struct InterruptException <: Exception
  by :: AbstractProcess
  cause :: Any
end

struct EmptySchedule <: Exception end

struct EventKey
  time :: Float64
  priority :: Int
  id :: UInt
end

function isless(a::EventKey, b::EventKey) :: Bool
  (a.time < b.time) || (a.time === b.time && a.priority > b.priority) || (a.time === b.time && a.priority === b.priority && a.id < b.id)
end

mutable struct Simulation <: Environment
  time :: Float64
  heap :: DataStructures.PriorityQueue{BaseEvent, EventKey}
  eid :: UInt
  sid :: UInt
  active_proc :: Union{AbstractProcess, Nothing}
  #monitored :: Array{Any,1}
  monitored :: Dict{Any, Any}
  simStartTime::Union{DateTime,Nothing}
  function Simulation(initial_time::Number=zero(Float64))
    # new(initial_time, DataStructures.PriorityQueue{BaseEvent, EventKey}(), zero(UInt), zero(UInt), nothing, Array{Any,1}[])
    # new(initial_time, DataStructures.PriorityQueue{BaseEvent, EventKey}(), zero(UInt), zero(UInt), nothing, Dict{Any, Any}())
    new(initial_time, DataStructures.PriorityQueue{BaseEvent, EventKey}(), zero(UInt), zero(UInt), nothing, Dict{Any, Any}(),nothing)
  end
end

function step(sim::Simulation)
  isempty(sim.heap) && throw(EmptySchedule())
  (bev, key) = DataStructures.peek(sim.heap)
  DataStructures.dequeue!(sim.heap)
  sim.time = key.time
  bev.state = processed
  for callback in bev.callbacks
    ########################################################
    # INITIAL PROBE ACTIVATION (the other is in the execute 
    # function)
    # First option. The Process object holds the FSMI so
    # the variables contained in the simulated process can
    # be found there. The Process object is in the callbacks 
    # so just before executing the callbacks, examine them
    # and if a Process is found extract the FSMI and send it 
    # to the probe
    ########################################################
    # if length(callback.args) > 0 && typeof(callback.args[1])==SimJulia.Process
    #   println("found a Process as callback")
    #   ProbeStructured(callback.args[1].fsmi)
    # else
    #   println("found something else than a Process")
    # end
    callback()
  end
end

function now(sim::Simulation)
  sim.time
end

function now(ev::AbstractEvent)
  return now(environment(ev))
end

function active_process(sim::Simulation) :: AbstractProcess
  sim.active_proc
end

function reset_active_process(sim::Simulation)
  sim.active_proc = nothing
end

function set_active_process(sim::Simulation, proc::AbstractProcess)
  sim.active_proc = proc
end
