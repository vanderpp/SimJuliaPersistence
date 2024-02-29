# mutable struct ProbeResultCar <: IProbeResult

#     state::Union{Missing,UInt8}
#     time::Union{Missing,Float64}
#     eid::Union{Missing,UInt64}
#     sid::Union{Missing,UInt64}
#     trip_duration::Union{Missing,Float64}
#     parking_duration::Union{Missing,Float64}
#     wait_duration::Union{Missing,Float64}

#     ProbeResultCar(args::NamedTuple) = ProbeResultCar(;args...)
#     ProbeResultCar(;
#         state = missing,
#         time = missing,
#         eid = missing,
#         sid = missing,
#         trip_duration = missing,
#         parking_duration = missing,
#         wait_duration = missing,
#     ) = (
#         x = new(missing,missing,missing,missing,missing,missing,);
#         x.state = state;
#         x.time = time;
#         x.eid = eid;
#         x.sid = sid;
#         x.trip_duration = trip_duration;
#         x.parking_duration = parking_duration;
#         x.wait_duration = wait_duration;
#         return x
#     )
  
#   end
  mutable struct ProbeResultCar <: IProbeResult
    parking_duration::Union{Missing, Float64}
    trip_duration::Union{Missing, Float64}
    wait_duration::Union{Missing, Float64}
    eid::Union{Missing, UInt64}
    state::Union{Missing, UInt8}
    sid::Union{Missing, UInt64}
    time::Union{Missing, Float64}
    ProbeResultCar(args::NamedTuple) = begin
            ProbeResultCar(; args...)
        end
    function ProbeResultCar(parking_duration, trip_duration, wait_duration, eid, state, sid, time; )
        obj = new()
        obj.parking_duration = parking_duration
        obj.trip_duration = trip_duration
        obj.wait_duration = wait_duration
        obj.eid = eid
        obj.state = state
        obj.sid = sid
        obj.time = time
        return obj
    end
    function ProbeResultCar(; parking_duration = missing, trip_duration = missing, wait_duration = missing, eid = missing, state = missing, sid = missing, time = missing)
        obj = new()
        obj.parking_duration = parking_duration
        obj.trip_duration = trip_duration
        obj.wait_duration = wait_duration
        obj.eid = eid
        obj.state = state
        obj.sid = sid
        obj.time = time
        return obj
    end
end