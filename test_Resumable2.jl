#include("./ResumableFunctions/ResumableFunctions.jl")
#using .ResumableFunctions #Distributions
using ResumableFunctions #Distributions

include("./SimProbe/SimProbe.jl")

ENV["JULIA_DEBUG"] = "all"

# @resumable function fibonacci(n::Int)
#     a = 1
#     b = 1
#     for i in 1:n
#         #i==n ? println(a) : nothing
#         @yield a
#         a, b = b, a+b
#     end
# end

#   The code below I used to reflect on the callable struct principle.
#   The idea is as follows: you define a type (a mutable struct)
#   Then you define a function that bears some name which is an identifier of such a struct.
#   Then to see the behaviour, you need to try to call that function:
#   (test)("a")
#   ERROR: UndefVarError: test not defined
#   Now instantiate the bla object
#   test=bla()
#   immediately, (test)("a") will work, I suppose since now there exists a reference to the name

# mutable struct bla
#     a::Int64
#     b::Int64

#     function bla(x, y)
#         inst = new()
#         inst.a = x
#         inst.b = y
#         inst
#     end

#     function bla()
#         inst = new()
#         inst.a = 0
#         inst.b = 1
#         inst
#     end
# end

# function (test::bla)(a)
#     println("returnOfTheFunction_$(a)")
# end

#   How is this principle used in resumablefunctions?
#   First you get a "type definition" containing the "slots"
#   Then there is a "call definition" which returns an instance of the type. 
#   The advantage/difference with what I did is that you can couple an sort of abstract identifier ##"varNNN" to the struct and the call definition uses the same name the original function has.
#   The original function is transformed into a state machine which is in fact a function identified by an instance of the type definition
#   Up until now we described the macro behaviour. You now have a type definition, a call definition and a Finite-State Machine.
#
#   Now you instantiate an "iterator" by calling the call definition   
#   julia> fibIter = fibonacci(5)
#   var"##258"(0x00, 100, 1000, 5, 20, 3:32, 4)
#   ====> This is an instance of the type definition
#
#   when you call this iterator (do fibIter() ) it cycles trough the fsm starting at the state defined in the instance of the type definition. 
#   So the state and the machine are coupled through the name.

# #   This one cannot be made resumable, @resumable doesn't allow for recursive definitions (this one generates an iterative process)
# function mygcd(x::Int64,y::Int64)
#     if  y == 0
#         return x
#     else
#         mygcd(y, mod(x,y))
#     end
# end

#   This one does the same but can be made resumable
@resumable function mygcd2(x::Int64,y::Int64) 
    while (y != 0)
        temp_x = y
        y = mod(x,y)
        x = temp_x
        @yield (x,y)
    end
    @yield x
end true

# #this is a caller which cycles through the iterator
# function callMygcd2(a1,a2)
#     gcdIterator = mygcd2(a1,a2)
#     gcdRes = Nothing
#     while typeof(gcdRes) == Tuple{Int64, Int64} || gcdRes == Nothing
#         @debug println(gcdRes)
#         gcdRes=gcdIterator()
#         #@yield gcdRes
#     end
#     return gcdRes
# end

#putting it to work to simplify fractions
# mutable struct fraction
#     numerator::Int64
#     denominator::Int64
#     function fraction(num, den)
#         frac = new()
#         frac.numerator = num
#         frac.denominator = den
#         frac
#     end
# end

# function simplifyFraction(theFraction)
#     thegcd = callMygcd2(theFraction.numerator, theFraction.denominator)
#     newFrac = fraction(theFraction.numerator/thegcd,theFraction.denominator/thegcd)
#     return newFrac
# end

#theFrac=fraction(95986,253)
#simplifyFraction(theFrac)

gcdIter = mygcd2(95986,253)
