module modle
    export test
    
    function test()
        theVal=@eval(Main,a)
        println(theVal)
    end
end

using .modle

a = "the line"
test()