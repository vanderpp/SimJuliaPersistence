"""
Main module for SimJulia.jl – a discrete event process oriented simulation framework for Julia.
"""

module SimJulia
  println("using local copy of SimJulia")
  #include("ResumableFunctions.jl")
  include("../SimProbe/SimProbe.jl")
  using DataStructures
  using Dates
  using ResumableFunctions
  using .SimProbe

  import Base.run, Base.isless, Base.show, Base.yield, Base.get
  import Base.(&), Base.(|)
  import Dates.now




  export AbstractEvent, Environment, value, state, environment
  export Event, succeed, fail, @callback, remove_callback
  export timeout
  export Operator, (&), (|), AllOf, AnyOf
  export @resumable, @yield
  export AbstractProcess, Simulation, run, now, active_process, StopSimulation

  export @makeMonitored #added for monitored processes, was in ProbeApp/Utils
  export @runPersisted

  export Process, @process, interrupt
  export Container, Resource, Store, put, get, request, release, cancel
  export nowDatetime
  
  #    adding exports  to explore internal behavior
  export EVENT_STATE, stop_simulation, step, schedule

  include("base.jl")
  include("events.jl")
  include("operators.jl")
  include("simulations.jl")
  include("processes.jl")
  include("resources/base.jl")
  include("resources/containers.jl")
  include("resources/stores.jl")
  include("utils/time.jl")
 
end
