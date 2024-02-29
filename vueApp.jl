#   Dependencies for VueJS
using HTTP,VueJS, DataFrames

#   Dependencies for ORM
using PostgresORM
using PostgresORM.PostgresORMUtil
using PostgresORM.Controller
using PostgresORM.CRUDType

#   Dependencies for ORM-Probe coupling
include("./SimProbe/ProbeApp.jl")
using .ProbeApp
using .ProbeApp.ProbeAppUtil
using .ProbeApp.Model

#   Dependencies for modelmetadata
include("./SimProbe/ProbeApp/modelClass.jl")
using .ModelMeta
using .ModelMeta.Model
using .ModelMeta.ModelMetaUtil

global reqVar
global data

"""
Function that returns a dataframe. The argument is a configured filterobject. It is the bridge between ORM and dataframes needed for VueJS.jl
"""
function requestDataframe(filterObj)
    function Obj2dict(obj)
        dct = Dict()
        fldnames = fieldnames(typeof(obj))
        for fldname in fldnames
            dct[fldname] = getproperty(obj,fldname)
        end
        return dct
    end
    
    resultset=retrieve_entity(filterObj,false,ProbeAppUtil.opendbconn())
    firstObj=resultset[1]
    df=DataFrame(Obj2dict(firstObj))

    for i in 2:length(resultset)
        currentObj=resultset[i]
        pushDct=Obj2dict(currentObj)
        push!(df,pushDct)
    end

    return df
end

"""
PART 1: Static Pages: Router function showModelMeta to generate a page
"""
function showModelMeta(req::HTTP.Request)
    #   Getting All metadata lines
    filterObj = ModelMeta.Model.simModelMeta()
    allDataTables = requestDataframe(filterObj)
    
    @el(tbl,"v-data-table",items=allDataTables,cols=5)

    return response(page([tbl]))
end
"""
PART 1: Static Pages: Router function probecarresult to generate a page
"""
 function probecarresult(req::HTTP.Request)
    #filterObj=ProbeApp.Model.ProbeResultcar00000000000000000014885220135270514525() #was on windows PC
    filterObj=ProbeApp.Model.ProbeResultcar00000000000000000016053362715619421237()
    theDf = requestDataframe(filterObj)
    
    filterArr=Any[]
    push!(filterArr,"")
    append!(filterArr,unique(theDf[!,:time]))
    
    @el(st,"v-text-field",label="Search")
    @el(sel,"v-select",label="Filter Time",items=filterArr,change="filter_dt(tbl,'time',sel.value)")
    @el(tbl,"v-data-table",items=theDf,item-class="cond_form",cols=7,binds=Dict("search"=>"st.value"),filter=Dict("time"=>"=="))
    
    return response(page([[st],[sel],[tbl]]))
 end
"""
PART 2: Dynamic Pages: function which generates a page displaying a dynamic dropdownlist showing all tables. The goal is to generate a parametrized (targetTbl) GET request.
"""
function showDataTables(req::HTTP.Request)
    #   getting all distinct TableNames/constructors
    filterObj = ProbeApp.objectDef.objectClass.Model.objectClassDefinition()
    allDataTables = requestDataframe(filterObj)
    
    TableNames = unique!(allDataTables[!,:objectClassName])

    #   Selector for the tables
    @el(sel,"v-select",items=TableNames,label="Select Data Table",                  change="open('/showTable?targetTbl='+sel.value)")    

    return response(page([sel]))
end
"""
PART 2: Dynamic Pages: function which parses a GET request for the targetTbl parameter. Then shows this table.
"""
function showTable(req::HTTP.Request)
    #retrieving the parameter from the GET request
    targetTbl = HTTP.queryparams(HTTP.URI(req.target))["targetTbl"]
    
    instantiator = eval(Symbol(targetTbl))

    filterobj = instantiator()

    global theDf = requestDataframe(filterobj)

    @el(tbl,"v-data-table",items=theDf,cols=ncol(theDf))
    
    return response(page([[html("div",targetTbl)],[tbl]]))

end
"""
Testing function, not needed anymore
"""
function sub_page2(req::HTTP.Request)
    #@el(sel2,"v-select",items=TableNames,label="Select Data Table",value=targettable,change="submit('sub_page',{targetTbl:sel2.value})")
    @el(sel2,"v-select",items=TableNames,label="Select Data Table",                  change="submit('sub_page',{targetTbl:sel2.value}).then(x=>el1.value=(x.responseText)).catch(x=>el1.value='error')")
    
    @el(el1,"v-text-field",value="default text")


    global reqVar = req
    global data=VueJS.parse(req)
    targetTbl = data.body["targetTbl"]
    println(targetTbl)
    return response(page([html("p","test")]))
end

const ROUTER = HTTP.Router()

#PART 1: Static Pages
HTTP.@register(ROUTER, "GET", "/showModelMeta", showModelMeta)
HTTP.@register(ROUTER, "GET", "/car", probecarresult)

#PART 2: Dynamic Pages
HTTP.@register(ROUTER, "GET", "/",                  showDataTables )
HTTP.@register(ROUTER, "GET", "/showDataTables",    showDataTables)
HTTP.@register(ROUTER, "GET", "/showTable",         showTable)


#HTTP.@register(ROUTER, "POST", "/showDataTables", showDataTables)
#HTTP.@register(ROUTER, "POST", "/showTable", showTable)
#HTTP.@register(ROUTER, "POST", "/sub_page2", sub_page2)

@async HTTP.serve(ROUTER,"127.0.0.1", 8000)