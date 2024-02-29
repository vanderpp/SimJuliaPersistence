module ModelMeta
    module ModelMetaUtil
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

        export simModelMeta

        abstract type IsimModelMeta <: IEntity end

        mutable struct simModelMeta <: IsimModelMeta
            modelName::Union{Missing, String}
            modelHashCode::Union{Missing, String}
            modelCreationTime::Union{DateTime,Missing}
            modeluuid::Union{UUID,Missing}
            lastused::Union{DateTime,Missing}
            
            simModelMeta(args::NamedTuple) = begin
                simModelMeta(; args...)
                end
            
            function simModelMeta(modelName, modelHashCode, modelCreationTime, modeluuid, lastused; )
                obj = new()
                obj.modelName = modelName
                obj.modelHashCode = modelHashCode
                obj.modelCreationTime = modelCreationTime
                obj.modeluuid = modeluuid
                obj.lastused = lastused
                return obj
            end
            
            function simModelMeta(; modelName = missing, modelHashCode = missing, modelCreationTime = missing, modeluuid = missing, lastused = missing)
                obj = new()
                obj.modelName = modelName
                obj.modelHashCode = modelHashCode
                obj.modelCreationTime = modelCreationTime
                obj.modeluuid = modeluuid
                obj.lastused = lastused
                return obj
            end
        end

    end

    module ORM
        module simModelMetaORM
            using ..ORM, ...Model
            using PostgresORM

            # Next double commented was operational before macro insertion.
            data_type = Model.simModelMeta #step 1
            PostgresORM.get_orm(x::Model.simModelMeta) = return(ORM.simModelMetaORM)
            get_schema_name() = "public"
            get_table_name() = "modelmetadata"

            # Declare the mapping between the properties and the database columns
            get_columns_selection_and_mapping() = return columns_selection_and_mapping
            const columns_selection_and_mapping = Dict(
                :modelName => "modelname", 
                :modelHashCode => "modelhashcode", 
                :modelCreationTime => "modelcreationtime",
                :modeluuid => "modeluuid",
                :lastused => "lastused",
            )


            # Declare which properties are used to uniquely identify an object
            #get_id_props() = return [:objectClassName,:objectClassFieldName,:objectClassFieldorm]
            #get_id_props() = return [:objectClassName,:objectClassFieldName]
            get_id_props() = return [:modelName,:modelHashCode]
        end
    end
end