module objectDef    
    using MacroTools
    using PostgresORM
    include("./abstract-types.jl")

    #postgres
    using PostgresORM
    using PostgresORM.PostgresORMUtil
    using PostgresORM.Controller
    using PostgresORM.CRUDType

    #   Dependencies for ORM-objectDef coupling
    include("objectClass.jl")
    using .objectClass
    using .objectClass.objectClassUtil
    using .objectClass.Model
    using .objectClass.ORM

    export @makeObjectDefModule

    
    struct objDef  #this is the object which couples the objectName and the dict prop->type
        objName::String
        objDict::Dict{Symbol,Symbol}
    end

    macro makeObjectDefModule()

        function createObjectsFromDB(mode::Symbol)
            
            function getDistinctObjectList()
                if mode == :all
                    df=execute_plain_query("Select distinct objectClassName from objectClassDefinition",missing,opendbconn())
                elseif mode ==:mostRecent
                    df=execute_plain_query("
                    with tbl as (
                                    SELECT 	modelname, 
                                            max(lastused) as lused 
                                    FROM 	public.modelmetadata 
                                    group by modelname
                                )
                                select 	'ProbeResult'||m.modelname||m.modelhashcode as objectclassname
                                from 	modelmetadata m inner join tbl t on 	m.modelname = t.modelname and
                                                                                m.lastused = t.lused",
                    missing,opendbconn())
                end
                objects = df[!,:objectclassname]
                println(objects)
                return objects
            end
        
            objectDefinitionsArray = objDef[]
            
            objects = getDistinctObjectList()
        
            for object in objects
                #creating the dict for the concerned object
                attribRows = retrieve_entity(objectClass.Model.objectClassDefinition(objectClassName=object),false,opendbconn())
                dct = Dict{Symbol,Symbol}()
                for attribRow in attribRows
                    dct[Symbol(attribRow.objectClassFieldName)]= Symbol(attribRow.objectClassFieldDataType)
                end
                theDefinition = objDef(object,dct)
        
                push!(objectDefinitionsArray,theDefinition)
            end
            println(objectDefinitionsArray)
            return objectDefinitionsArray
        end

        dbObjectDefinitions = createObjectsFromDB(:all)
        dbmostRecentObjectDefinitions = createObjectsFromDB(:mostRecent)

        function objToObjDef(obj)
            type_name = Symbol(obj.objName)
            struct_name = :($type_name)
            slots = eval(obj.objDict) #slots is a dict

            #   args constructor
            constr_def = Dict{Symbol, Any}()
            constr_def[:name]=:($type_name)
            constr_def[:args]=collect(keys(slots))
            constr_def[:kwargs]=Any[] 
            constr_def[:body]=  quote
                                    obj = new()
                                    $((:(obj.$slotname=$slotname) for (slotname, slottype) in slots)...)
                                    return obj
                                end
            constr_def[:whereparams] = ()
            constr_expr = combinedef(constr_def)
            
            #   kwargs constructor
            kwconstr_def = Dict{Symbol, Any}()
            kwconstr_def[:name]=:($type_name)
            kwconstr_def[:args]=Any[]
            kwconstr_def[:kwargs]= map(x-> :($(Expr(:kw, x, :missing))),collect(keys(slots)))
            kwconstr_def[:body]=  quote
                                    obj = new()
                                    $((:(obj.$slotname=$slotname) for (slotname, slottype) in slots)...)
                                    return obj
                                end
            kwconstr_def[:whereparams] = ()

            kwconstr_expr = combinedef(kwconstr_def)

            type_expr = quote
                $(:(export $struct_name))
                mutable struct $(:($struct_name <: IProbeResult))
                    $((:($slotname :: Union{Missing,$slottype}) for (slotname, slottype) in slots)...)
                    $(:($struct_name(args::NamedTuple)=($struct_name(;args...))))
                    $(constr_expr)
                    $(kwconstr_expr)
                end
            end
            return type_expr
        end

        function objToConstrName(obj)
            #type_name = String(obj.objName)[12:end]
            type_name = String(obj.objName)[12:end-38]
            func_name = Symbol(obj.objName)
            println(type_name,func_name)
            return (type_name,func_name)
        end

        quotedObjDefArr = map(objToObjDef,dbObjectDefinitions)
        constructorNamesArr = map(objToConstrName,dbmostRecentObjectDefinitions)

        # final = quote
        #     $((:($quotedObjDef) for quotedObjDef in quotedObjDefArr)...)
        # end

        final = :(
            module Model
                using Dates, TimeZones, UUIDs, PostgresORM
                include("./ProbeApp/abstract-types.jl")
                constructors = Dict{Any, Any}()
                #constructors[:testKey]=:testValue  To be replaced by generated quoted expression containing constructors
                $((:($quotedObjDef) for quotedObjDef in quotedObjDefArr)...)
                $((:(constructors[$key]=$constructorName) for (key,constructorName) in constructorNamesArr)...)

            end
        )
        esc(:($final))
    end # macro makeObjectDef
end # module objectDef