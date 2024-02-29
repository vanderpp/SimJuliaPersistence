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

function persist(obj)   
    dbconn = opendbconn()
    create_entity!(obj,dbconn)
    closedbconn(dbconn)
end

#   Populating the db is some utility function
function populateDB()
    #todo: this must be fed in the db either by code analysis or through a nice interface on this table
    theNameCar="ProbeResultCar"
    theFieldsCar=Dict{Symbol,Symbol}(:state => :UInt8,:time => :Float64,:eid => :UInt64,:sid => :UInt64,:trip_duration => :Float64,:parking_duration => :Float64,:wait_duration => :Float64)
            
    theNameTrafficLight="ProbeResultTrafficLight"
    theFieldsTrafficLight=Dict{Symbol,Symbol}(:state => :UInt8,:time => :Float64,:eid => :UInt64,:sid => :UInt64,:trafficLight_waitTime => :Float64)

    for (key,values) in theFieldsCar
        persist(objectClass.Model.objectClassDefinition(theNameCar,string(key),string(values)))
    end

    for (key,values) in theFieldsTrafficLight
        persist(objectClass.Model.objectClassDefinition(theNameTrafficLight,string(key),string(values)))
    end
end

struct objectDef  #this is the object which couples the objectName and the dict prop->type
    objName::String
    objDict::Dict{Symbol,Symbol}
end

function createObjectsFromDB()
    
    function getDistinctObjectList()
        df=execute_plain_query("Select distinct objectClassName from objectClassDefinition",missing,opendbconn())
        objects = df[!,:objectclassname]
        return objects
    end

    objectDefinitionsArray = objectDef[]
    
    objects = getDistinctObjectList()

    for object in objects
        #creating the dict for the concerned object
        attribRows = retrieve_entity(objectClass.Model.objectClassDefinition(objectClassName=object),false,opendbconn())
        dct = Dict{Symbol,Symbol}()
        for attribRow in attribRows
            dct[Symbol(attribRow.objectClassFieldName)]= Symbol(attribRow.objectClassFieldDataType)
        end
        theDefinition = objectDef(object,dct)

        push!(objectDefinitionsArray,theDefinition)
    end
    
    return objectDefinitionsArray
end