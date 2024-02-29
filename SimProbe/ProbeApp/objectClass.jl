module objectClass
    module objectClassUtil
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

        export objectClassDefinition  # a objectClassDefinition object contains info the macro @makeObjectDef needs to use: name(String) and the fields as a Dict{Symbol,Symbol} of the object class to create 

        abstract type IObjectClassDefinition <: IEntity end

        mutable struct objectClassDefinition <: IObjectClassDefinition
            objectClassName::Union{Missing, String}
            objectClassFieldName::Union{Missing, String}
            objectClassFieldDataType::Union{Missing, String}
            
            objectClassDefinition(args::NamedTuple) = begin
                objectClassDefinition(; args...)
                end
            
            function objectClassDefinition(objectClassName, objectClassFieldName, objectClassFieldDataType; )
                obj = new()
                obj.objectClassName = objectClassName
                obj.objectClassFieldName = objectClassFieldName
                obj.objectClassFieldDataType = objectClassFieldDataType
                return obj
            end
            
            function objectClassDefinition(; objectClassName = missing, objectClassFieldName = missing, objectClassFieldDataType = missing)
                obj = new()
                obj.objectClassName = objectClassName
                obj.objectClassFieldName = objectClassFieldName
                obj.objectClassFieldDataType = objectClassFieldDataType
                return obj
            end
        end

    end

    module ORM
        module objectClassDefinitionORM
            using ..ORM, ...Model
            using PostgresORM

            # Next double commented was operational before macro insertion.
            data_type = Model.objectClassDefinition #step 1
            PostgresORM.get_orm(x::Model.objectClassDefinition) = return(ORM.objectClassDefinitionORM)
            get_schema_name() = "public"
            get_table_name() = "objectClassDefinition"

            # Declare the mapping between the properties and the database columns
            get_columns_selection_and_mapping() = return columns_selection_and_mapping
            const columns_selection_and_mapping = Dict(
                :objectClassName => "objectclassname", 
                :objectClassFieldName => "objectclassfieldname", 
                :objectClassFieldDataType => "objectclassfielddatatype", 
            )


            # Declare which properties are used to uniquely identify an object
            #get_id_props() = return [:objectClassName,:objectClassFieldName,:objectClassFieldDataType]
            get_id_props() = return [:objectClassName,:objectClassFieldName]
        end
    end
end