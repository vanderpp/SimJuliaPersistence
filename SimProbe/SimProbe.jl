module SimProbe
    #   Dependencies for ORM
    using PostgresORM
    using PostgresORM.PostgresORMUtil
    using PostgresORM.Controller
    using PostgresORM.CRUDType

    #   Dependencies for ORM-Probe coupling
    include("ProbeApp.jl")
    using .ProbeApp
    using .ProbeApp.ProbeAppUtil
    using .ProbeApp.Model

    export Probe, ProbeStructured
    """
    ProbeStructured takes the fsmi instance directly. It can be used with ResumableFunctions or the "wrapper" in a callback
    """
    function ProbeStructured(fsmi_instance)
        #if ENV["SIMPROBE_MODE"]=="persist"
            function monitoredProcess(fsmiInstance)
                result = getkey(fsmiInstance.sim.monitored, typeof(fsmiInstance), false)
                if result ≠ false
                    result = true
                end
                return result
            end

            function persist(obj)   
                dbconn = opendbconn()
                create_entity!(obj,dbconn)
                closedbconn(dbconn)
            end

            #   Part 1: extracting semistatic metadata (environment and state)
            simState = fsmi_instance._state
                        
            if Symbol("sim") ∈ collect(fieldnames(typeof(fsmi_instance)))
                simTime = fsmi_instance.sim.time
                simEid = fsmi_instance.sim.eid
                simSid = fsmi_instance.sim.sid
                simSTartTime = fsmi_instance.sim.simStartTime
            end
            
            if monitoredProcess(fsmi_instance) #&& ENV["SIMPROBE_MODE"]=="persist"
                instantiator = get(fsmi_instance.sim.monitored, typeof(fsmi_instance),false)
                instProbeResult = instantiator()
                setproperty!(instProbeResult,Symbol("state"),simState)
                setproperty!(instProbeResult,Symbol("time"),simTime)
                setproperty!(instProbeResult,Symbol("eid"),simEid)
                setproperty!(instProbeResult,Symbol("sid"),simSid)
                setproperty!(instProbeResult,Symbol("simStartTime"),simSTartTime)
                
                #   Part 2: extracting dynamic data (state variables of the fsmi, aka variables in the sim)
                fsmi_slots=collect(fieldnames(typeof(fsmi_instance)))

                #   Removing the slots we already have
                filter!(e->e≠Symbol("sim"),fsmi_slots)
                filter!(e->e≠Symbol("_state"),fsmi_slots)
                filter!(e->e≠Symbol("monitored"),fsmi_slots)
            
                # TODO: implement a mechanism that removes un-monitored slots from the probe
                # This could be driven by the definition of the object definition for the persist part

                for fsmiSlot in fsmi_slots
                    setproperty!(instProbeResult, fsmiSlot,getfield(fsmi_instance,fsmiSlot))
                end
                
                persist(instProbeResult)
            end
        #end
    end

    function Probe(ev, Process)
        #Probe is a wrapper for ProbeStructured to use as a callback.
        ProbeStructured(Process.fsmi)
    end
end