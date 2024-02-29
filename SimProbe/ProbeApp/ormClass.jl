module ormClass
    module ormClassUtil
        using LibPQ
    
        export opendbconn, closedbconn

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
    end

    module Model
        using Dates, TimeZones, UUIDs, PostgresORM

        export ormClassDefinition

        abstract type IormClassDefinition <: IEntity end

        mutable struct ormClassDefinition <: IormClassDefinition
            objectClassName::Union{Missing, String}
            objectClassFieldName::Union{Missing, String}
            objectClassFieldorm::Union{Missing, String}
            objectClassFieldormpk::Union{Missing, Bool}
            
            ormClassDefinition(args::NamedTuple) = begin
                ormClassDefinition(; args...)
                end
            
            function ormClassDefinition(objectClassName, objectClassFieldName, objectClassFieldorm, objectClassFieldormpk ; )
                obj = new()
                obj.objectClassName = objectClassName
                obj.objectClassFieldName = objectClassFieldName
                obj.objectClassFieldorm = objectClassFieldorm
                obj.objectClassFieldormpk = objectClassFieldormpk
                return obj
            end
            
            function ormClassDefinition(; objectClassName = missing, objectClassFieldName = missing, objectClassFieldorm = missing, objectClassFieldormpk = missing)
                obj = new()
                obj.objectClassName = objectClassName
                obj.objectClassFieldName = objectClassFieldName
                obj.objectClassFieldorm = objectClassFieldorm
                obj.objectClassFieldormpk = objectClassFieldormpk
                return obj
            end
        end

    end

    module ORM
        module ormClassDefinitionORM
            using ..ORM, ...Model
            using PostgresORM

            # Next double commented was operational before macro insertion.
            data_type = Model.ormClassDefinition #step 1
            PostgresORM.get_orm(x::Model.ormClassDefinition) = return(ORM.ormClassDefinitionORM)
            get_schema_name() = "public"
            get_table_name() = "objectClassDefinition"

            # Declare the mapping between the properties and the database columns
            get_columns_selection_and_mapping() = return columns_selection_and_mapping
            const columns_selection_and_mapping = Dict(
                :objectClassName => "objectclassname", 
                :objectClassFieldName => "objectclassfieldname", 
                :objectClassFieldorm => "objectclassfieldorm", 
                :objectClassFieldormpk => "objectclassfieldormpk", 
            )


            # Declare which properties are used to uniquely identify an object
            #get_id_props() = return [:objectClassName,:objectClassFieldName,:objectClassFieldorm]
            get_id_props() = return [:objectClassName,:objectClassFieldName]
        end
    end
end