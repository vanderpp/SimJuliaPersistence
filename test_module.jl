module testeval
    function __init__()
        println("I will only execute after first usage of the module")
    end    
    # export @theMacro
    # macro theMacro()
    #     body = quote
    #         function showTextTwice(arg)
    #             println(:($arg))
    #             println(:($arg))
    #         end
    #     end
    #     esc(:($body))
    # end
    export theFunction
    function theFunction(arg)
        println(arg)
        println(arg)
    end
    println("call from module body")
end
