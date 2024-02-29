module ProbeApp
    greet() = println("Hello from ProbeApp")
    #Static module containing the DB connection
    #TODO: we could define this configuration externally.
    module ProbeAppUtil
        export opendbconn, closedbconn #, makeMonitored
        include("./ProbeApp/utils.jl")
    end
    
    #generating the Model module. This module contains only objectdefinitions. 
    include("./ProbeApp/objectDef.jl")
    using .objectDef

    @makeObjectDefModule

    #generating the ORM module. This module contains submodules which in their turn contain the mapping
    include("./ProbeApp/ormDef.jl")
    using .ormDef
    
    @makeOrmDefModule
    
end