using LibPQ

function opendbconn()
    database = "probeapp"
    user = "probeapp"
    host = "127.0.0.1"
    port = "5432"
    password = "1234"

    conn = LibPQ.Connection("host=$(host)
                             port=$(port)
                             dbname=$(database)
                             user=$(user)
                             password=$(password)
                             "; throw_error=true)
    return conn
end

function closedbconn(conn)
    close(conn)
end

macro makeMonitored()
    final = quote
        if @isdefined(MON_PROC)
            include("./SimProbe/ProbeApp.jl")
            for proc in MON_PROC
                println(string("doing: ",proc))
                prog=string("sim.monitored[typeof(",proc,"(sim))]=ProbeApp.Model.constructors[\"",proc,"\"]")
                eval(Meta.parse(prog))
            end
        else 
            println("No monitored functions defined...")
        end
    end
    esc(:($final))
end