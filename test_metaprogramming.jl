prog1 = "1 + 1" #string representing a direct call

exp1 = Meta.parse(prog1) 
#this is an expression, and is callable. the expression is ===> :(1 + 1)

#you can create the expression directly:

exp2 = Expr(:call, :+, 1, 1)

exp1 == exp2 # ===> true

#or use quoting:

exp3 = :(1 + 1)

exp1 == exp2 == exp3 # ===> true, so all of these ways to generate the expression mean the same thing.

#finally evaluate the expression

eval(exp1) == eval(exp2) == eval(exp3) == 2

##################################
# what about function definitions?
##################################

prog2 = "function adder() 1 + 1 end"
exp4 = Meta.parse(prog2)

# :(function adder()
#       #= none:1 =#
#       #= none:2 =#
#       1 + 1
#   end)

the_adder = eval(exp4)

the_adder() # ==> gives 2

#using quoting

