using ResumableFunctions, Distributions

@resumable function oneWayPingPong()
    while true
        @yield "ping"
        @yield "pong"
    end
end

function doIt(n)
    pingponger = oneWayPingPong()
    for i in 1:n
        println(pingponger())
    end 
end

@resumable function ping()
    msg="init"
    while true
        msg = @yield    if msg == "pong" || msg == "init" 
                            println("got a " * msg * " sending a ping back")
                            "ping" 
                            
                        else 
                            return 
                        end
    end
end

@resumable function pong()
    msg="init"
    while true
        msg = @yield    if msg == "ping"|| msg == "init" 
                            println("got a " * msg * " sending a pong back")                
                            "pong" 
                        else 
                            return 
                        end
                        @yield "stopping a bit"
    end
end

function game()
    ping_player = ping()
    pong_player = pong()
    ping_out = ping_player()
    while true
        println("current_ping_out = " * ping_out)
        pong_out = pong_player(ping_out)
        println("current_pong_out = " * pong_out)
        ping_out = ping_player(pong_out)
        sleep(1)
    end
end


ping_player = ping()
pong_player = pong()

@resumable function two_state()
    while true
        @yield "state1"
        @yield "state2"
    end
end

