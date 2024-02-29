include("./SimProbe/ProbeApp/modelClass.jl")
using .ModelMeta
using .ModelMeta.Model
using .ModelMeta.ModelMetaUtil

using PostgresORM
using PostgresORM.PostgresORMUtil
using PostgresORM.Controller
using PostgresORM.CRUDType

#theHash = 1734
theHash = 17342023196470750240
theName = "car"

theObj = simModelMeta(theName,theHash)

dbconn = opendbconn()
create_entity!(theObj,dbconn)
closedbconn(dbconn)
println("Done")