module ormDef
    
    #postgres
    using PostgresORM
    using PostgresORM.PostgresORMUtil
    using PostgresORM.Controller
    using PostgresORM.CRUDType

    #   Dependencies for ORM-objectDef coupling
    include("ormClass.jl")
    using .ormClass
    using .ormClass.ormClassUtil
    using .ormClass.Model
    using .ormClass.ORM
    
    export @makeOrmDefModule
    
    struct ormDefinition  
        ormName::String
        ormDict::Dict{Symbol,String}
        ormPKs::Array{Symbol,1}
    end
    
    macro makeOrmDefModule()
        
        function createOrmsFromDB()
            function getDistinctOrmList()
                df=execute_plain_query("Select distinct objectClassName from objectClassDefinition",missing,opendbconn())
                orms = df[!,:objectclassname]
                return orms
            end

            ormDefinitionArray = ormDefinition[]
            
            orms = getDistinctOrmList()

            for orm in orms
                #creating the dict which contains the mapping objectFieldName to TableColumn
                attribRows = retrieve_entity(ormClass.Model.ormClassDefinition(objectClassName=orm),false,opendbconn())
                dct = Dict{Symbol,String}()
                pkArr=Symbol[]
                for attribRow in attribRows
                    dct[Symbol(attribRow.objectClassFieldName)]= lowercase(attribRow.objectClassFieldorm)
                    if attribRow.objectClassFieldormpk
                        push!(pkArr,Symbol(attribRow.objectClassFieldName))
                    end
                end
                push!(ormDefinitionArray,ormDefinition(orm,dct,pkArr))
            end

            return ormDefinitionArray
        end
        
        dbOrmDefinitions = createOrmsFromDB()

        function ormObjToOrmExpr(def::ormDefinition)
            symObj = Symbol(def.ormName)
            symORM = Symbol(string(def.ormName,"ORM"))
            moduleBody = quote
                    using ..ORM, ...Model
                    using PostgresORM

                    data_type= Model.$symObj
                    PostgresORM.get_orm(x::Model.$symObj) = return(ORM.$symORM)
                    get_schema_name() = "public"
                    get_table_name() = eval($def.ormName)
                    
                    # Declare the mapping between the properties and the database columns
                    get_columns_selection_and_mapping() = return columns_selection_and_mapping
                    const columns_selection_and_mapping = eval($def.ormDict)
                    get_id_props() = return eval($def.ormPKs)
            end

            result =    :(
                            module $symORM
                                $moduleBody 
                            end
                        )
            return result
        end

        quotedOrmDefArr = map(ormObjToOrmExpr,dbOrmDefinitions)
        esc(    
            :(
                module ORM
                    testOuter() = "returnOuter"
                    $(:(module test
                        testInner() = "returnInner"
                        end
                    ))
                    $((:($quotedOrmDef) for quotedOrmDef in quotedOrmDefArr)...)
                end
            )
        )

    end
end