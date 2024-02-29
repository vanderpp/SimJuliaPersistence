module CreateConfig
    
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

    #   Dependencies for ORM-objectDef coupling
    include("ormClass.jl")  
    using .ormClass
    using .ormClass.ormClassUtil
    using .ormClass.Model
    using .ormClass.ORM

    #   Dependencies for model metadata 
    include("modelClass.jl")
    using .ModelMeta
    using .ModelMeta.Model
    using .ModelMeta.ModelMetaUtil
    using MacroTools
    using Random
    using UUIDs
    using Dates
    
    export createVersionRecord
    export saveSlotsToDb
    export dataTableBuilder
    

    function saveSlotsToDb(fname::Symbol,dct::Dict{Symbol, Any})
        
        versionRecord = createVersionRecord(fname, dct)
        createDataConfigRecords(fname::Symbol,dct::Dict{Symbol, Any},versionRecord)
        dataTableBuilder(string("ProbeResult",fname,versionRecord))                    #After analysis of the model function and persistence of config, the data table gets constructed.        
    end
    
    """
    This function creates the datatable for a given shadowobject, based upon the config from the datatable.
    The SQL uses an IF NOT EXISTS so if the same table was already present, the SQL is not effective and data is kept.
    
    """
    function dataTableBuilder(objectName)
        
        """
        Function that fetches all configlines from the db for a specific table
        """
        function fetchConfigObjects(objectName::String, dbconn)
            obj=objectClassDefinition(objectClassName=string(objectName))
            result = retrieve_entity(obj,false,dbconn)
            return result
        end

        """
        Function that transforms a config object to a DDL fragment, and tries to solve ORM impedance mismatch
        """
        function ColConstructor(theObj::objectClass.Model.objectClassDefinition)
            typeMachingDict = Dict{String,String}(  "UInt64" => "bigint", 
                                                    "UInt8"=>"integer",
                                                    "Int64"=>"integer",
                                                    "Float64"=>"numeric",
                                                    "DateTime" => "timestamp")
            return string(theObj.objectClassFieldName," ", typeMachingDict[theObj.objectClassFieldDataType])
        end
        
        dbconn = objectClass.objectClassUtil.opendbconn()
        
        #   Dropping the table if it exists
        #   dropExisting="DROP TABLE IF EXISTS public.$(lowercase(objectName))"
        #   execute_plain_query(dropExisting,missing,dbconn)
        
        #   Creating the newe table
        colConfigObj = fetchConfigObjects(objectName, dbconn)
        columnDDLs = map(ColConstructor,colConfigObj)
        
        DDLqry="CREATE TABLE IF NOT  EXISTS public.$(lowercase(objectName)) ("
        for colDDL in columnDDLs
            DDLqry = DDLqry * colDDL *", "
        end
        DDLqry = DDLqry * "CONSTRAINT $(lowercase(objectName))_pkey PRIMARY KEY (state, time, simstarttime)) TABLESPACE pg_default"
        execute_plain_query(DDLqry,missing,objectClass.objectClassUtil.opendbconn())

        #   Altering the owner of the table
        alterOwner = "ALTER TABLE IF EXISTS public.$(lowercase(objectName)) OWNER to probeapp"
        execute_plain_query(alterOwner,missing,dbconn)

        objectClass.objectClassUtil.closedbconn(dbconn)
        
        println("[info] Data Table for $objectName created")
    end
    """
    function creates a modelmetadata record if the model did not exist before. If a model using slots where these slots existed before in a model, we use 
        that model again. Even if the model was semantically different.
    """
    function createVersionRecord(fname::Symbol,dct::Dict{Symbol, Any})
        slotsHash=lpad(string(hash(dct)),38,"0")
        nice_name = String(fname)
        currentTime=now()
        modelCreationTime = currentTime
        currentModelUsetimestamp = currentTime
        modelUUID = uuid1(MersenneTwister())
        theObj = simModelMeta(nice_name,slotsHash,modelCreationTime,modelUUID,currentModelUsetimestamp )
        
        dbconn = ModelMeta.ModelMetaUtil.opendbconn()
        queryObj = simModelMeta(nice_name,slotsHash,missing,missing,missing)
        resultSet = retrieve_entity(queryObj,false,dbconn)
        if length(resultSet)==0
            create_entity!(theObj,dbconn)
            println("[info] Version record concerning slots $nice_name created. Hascode is $slotsHash")
        else
            println("[info] Found a version record concerning slots $nice_name. Existing hascode is $slotsHash  ")
            updObj=resultSet[1]
            println(updObj)
            updObj.lastused = currentModelUsetimestamp
            println(updObj)
            update_entity!(updObj,dbconn)
        end
        ModelMeta.ModelMetaUtil.closedbconn(dbconn)       
        return slotsHash 
    end

    function createDataConfigRecords(fname::Symbol,dct::Dict{Symbol, Any},versionRecord)
        function persist(obj,mode::Symbol)   
            if mode == :CREATE
                dbconn = objectClass.objectClassUtil.opendbconn()
                create_entity!(obj,dbconn)
                objectClass.objectClassUtil.closedbconn(dbconn)
            elseif mode == :UPDATE
                dbconn = ormClass.ormClassUtil.opendbconn() 
                update_entity!(obj,dbconn)
                ormClass.ormClassUtil.closedbconn(dbconn)
            else
                println("[!]    Unknown Persist Mode")
            end
            
        end

        function deleteObjClassDef(fname,versionRecord)
            dbconn = objectClass.objectClassUtil.opendbconn()
            qry="DELETE FROM objectclassdefinition where objectclassname = '$(string("ProbeResult",fname,versionRecord))'"
            execute_plain_query(qry,missing,dbconn)
            objectClass.objectClassUtil.closedbconn(dbconn)
        end
        
        

        workingDict=deepcopy(dct)    
        delete!(workingDict,:sim)

        workingDict[:eid]=:UInt64
        workingDict[:sid]=:UInt64
        workingDict[:state]=:UInt8
        workingDict[:time]=:Float64
        workingDict[:simStartTime]=:DateTime

        deleteObjClassDef(fname,versionRecord)    #analysis of the model function takes place on every occasion. The config table gets updated with the new layout of the slots.

        for (slotName, slotType) in workingDict
            obj=objectClassDefinition(string("ProbeResult",fname,versionRecord), string(slotName), string(slotType))
            persist(obj,:CREATE)
        end

        for (slotName, slotType) in workingDict
            if slotName in [:state,:time,:simStartTime]
                pkValue=true
            else
                pkValue=false
            end
            obj=ormClassDefinition(string("ProbeResult",fname,versionRecord), string(slotName), string(slotName), pkValue)

            persist(obj,:UPDATE)
        end
        println("[info] Config Table for $fname OK")
    end

end