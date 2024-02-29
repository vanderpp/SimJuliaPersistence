mutable struct ProbeResultTrafficLight <: IProbeResult

    state::Union{Missing,UInt8}
    time::Union{Missing,Float64}
    eid::Union{Missing,UInt64}
    sid::Union{Missing,UInt64}
    trafficLight_waitTime::Union{Missing,Float64}

    ProbeResultTrafficLight(args::NamedTuple) = ProbeResultTrafficLight(;args...)
    ProbeResultTrafficLight(;
        state = missing,
        time = missing,
        eid = missing,
        sid = missing,
        trafficLight_waitTime = missing,
    ) = (
        x = new(missing,missing,missing,missing,missing,);
        x.state = state;
        x.time = time;
        x.eid = eid;
        x.sid = sid;
        x.trafficLight_waitTime = trafficLight_waitTime;
        return x
    ) 
end 