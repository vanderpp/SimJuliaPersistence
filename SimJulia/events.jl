struct Event <: AbstractEvent
  bev :: BaseEvent
  function Event(env::Environment)
    new(BaseEvent(env))
  end
end

function succeed(ev::Event; priority::Int=0, value::Any=nothing) :: Event
  state(ev) !== idle && throw(EventNotIdle(ev))
  schedule(ev; priority=priority, value=value)
end

function fail(ev::Event, exc::Exception; priority::Int=0) :: Event
  succeed(ev; priority=priority, value=exc)
end

struct Timeout <: AbstractEvent
  bev :: BaseEvent
  function Timeout(env::Environment)
    new(BaseEvent(env))
  end
end

function timeout(env::Environment, delay::Number=0; priority::Int=0, value::Any=nothing)
  schedule(Timeout(env), delay; priority=priority, value=value)
end

# #Piet added to get this automatically in the scope of the run
# macro makeMonitored()
#   final = quote
#       if @isdefined(MON_PROC)
#           include("./SimProbe/ProbeApp.jl")
#           for proc in MON_PROC
#               println(string("doing: ",proc))
#               prog=string("sim.monitored[typeof(",proc,"(sim))]=ProbeApp.Model.constructors[\"",proc,"\"]")
#               eval(Meta.parse(prog))
#           end
#       else 
#           println("No monitored functions defined...")
#       end
#   end
#   esc(:($final))
# end

macro runPersisted(env,runtime::Int64)#,monitored::Bool)
  time = eval(runtime)
  envStr = string(env)
  envSym = Symbol(envStr)
  monitored = true


  runProg = quote
    $(:(using Dates))
    $(:($envSym.simStartTime=now()))
    $(:(run($env,$time)))
    $(:($envSym.simStartTime=nothing))
  end
  
  try
    mon_proc=@eval(Main, MON_PROC)
    @isdefined(mon_proc)
  catch
    monitored = false
  end

  if monitored
    mon_proc_tuples=map(x->(x,Symbol(x)),@eval(Main, MON_PROC))
    makeMon = quote
      $(:(include("./SimProbe/ProbeApp.jl")))
      $((:($envSym.monitored[typeof($procSym($envSym))]=ProbeApp.Model.constructors[$procStr]) for (procStr,procSym) in mon_proc_tuples)...)
    end
  else
    makeMon = quote nothing end
  end

  esc(:($makeMon,$runProg))
end

# function run(env::Environment, until::Number=typemax(Float64); monitored=false ) #trial to move the promotion of candidate monitored to monitored: gives the world problem
#   # if monitored
#   #   printstyled("Run Function: promotion of Candidate-monitored will take place now\r\n",color=:red)
#   #   mon_proc=@eval(Main, MON_PROC)  #MON_PROC is an array, set by @resumable which contains the nice_names of the functions (processes) to be monitored
#   #   printstyled(mon_proc, color=:blue)
#   #   print("\r\n")
#   #   include("./SimProbe/ProbeApp.jl")
#   #   for proc in mon_proc
#   #     #eval(Meta.parse(string("sim.monitored[typeof(",proc,"(sim))]=ProbeApp.Model.constructors[\"",proc,"\"]")))

#   #     constructor = eval(Meta.parse(string("ProbeApp.Model.constructors[\"",proc,"\"]")))
#   #     println("1) Constructor: $constructor")
      
#   #     println("2) Determining type")
#   #     type=eval(Meta.parse(string("typeof(Main.",proc,"(","Main.sim","))")))
#   #     println(type)


#   #     println("3) Setting sim.monitored[$proc]=$constructor")
#   #     env.monitored[type]=constructor
#   #   end
#   # end
#   mon_proc=@eval(Main, MON_PROC)
#   println("Still in use...")
#   println(mon_proc)
  
#   run(env, timeout(env, until-now(env)))
# end

# Original run function
function run(env::Environment, until::Number=typemax(Float64))
  run(env, timeout(env, until-now(env)))
end