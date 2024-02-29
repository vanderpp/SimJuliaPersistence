struct Initialize <: AbstractEvent
  bev :: BaseEvent
  function Initialize(env::Environment)
    new(BaseEvent(env))
  end
end

mutable struct Process <: DiscreteProcess
  bev :: BaseEvent
  fsmi :: ResumableFunctions.FiniteStateMachineIterator
  target :: AbstractEvent
  resume :: Function
  function Process(func::Function, env::Environment, args...; kwargs...)
    proc = new()
    proc.bev = BaseEvent(env)
    proc.fsmi = func(env, args...; kwargs...)
    proc.target = schedule(Initialize(env))
    proc.resume = @callback execute(proc.target, proc)
    proc
  end
end

macro process(expr)
  expr.head !== :call && error("Expression is not a function call!")
  esc(:(Process($(expr.args...))))
end

function execute(ev::AbstractEvent, proc::Process)
  try
    env = environment(ev)
    set_active_process(env, proc)
    #println(string(env.active_proc))
    target = proc.fsmi(value(ev))
    reset_active_process(env)
    if proc.fsmi._state === 0xff
      schedule(proc; value=target)
    else
      proc.target = state(target) == processed ? timeout(env; value=value(target)) : target
      proc.resume = @callback execute(proc.target, proc)
      ###########################################################################
      # SECOND PROBE OPTION (the other is in the step 
      # function) via the callbacks.
      # We add a callback that is executed after a step().
      # The callback consists of sending the Process 
      # object to the Probe which is a wrapper to comply
      # with callback function requirements. Probe will 
      # extract the FSMI and send it to the ProbeStructured function.
      ###########################################################################

      # inserting the probe callback here
      @callback Probe(proc.target, proc)
    end
  catch exc
    rethrow(exc)
  end
end

struct Interrupt <: AbstractEvent
  bev :: BaseEvent
  function Interrupt(env::Environment)
    new(BaseEvent(env))
  end
end

function execute_interrupt(ev::Interrupt, proc::Process)
  remove_callback(proc.resume, proc.target)
  execute(ev, proc)
end

function interrupt(proc::Process, cause::Any=nothing)
  env = environment(proc)
  if proc.fsmi._state !== 0xff
    proc.target isa Initialize && schedule(proc.target; priority=typemax(Int))
    target = schedule(Interrupt(env); priority=typemax(Int), value=InterruptException(active_process(env), cause))
    @callback execute_interrupt(target, proc)
  end
  timeout(env; priority=typemax(Int))
end
