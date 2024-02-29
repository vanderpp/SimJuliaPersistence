include("./ResumableFunctions/ResumableFunctions.jl")
include("./SimProbe/SimProbe.jl")
using .ResumableFunctions
using .SimProbe
ENV["JULIA_DEBUG"] = "none"

@resumable function car()
  msg = "brand new car"
  p = 0
  d = 0
  while true
    #   parking sequence
    msg = "parking"
    p += 1
    @yield msg
    
    #   driving sequence
    msg = "driving"
    d += 1
    @yield msg
  end 
end

# carIter=car()

# for i in 1:10
#   println("---- Iter_$i----")
#   retVal = carIter()
#   println(retVal)
# end

# @resumable function fibonacci(n::Int)
#   a = 1
#   b = 1
#   for i in 1:n
#       #i==n ? println(a) : nothing
#       @yield a
#       a, b = b, a+b
#   end
# end

# fibIter = fibonacci(10)