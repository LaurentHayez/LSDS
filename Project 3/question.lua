--[[
**
** Author:      Laurent Hayez
** Date:        03 dec 2015
** File:        Firefly implementation (adaptive Ermentrout model)
**
--]]

require("splay.base")

verbose = true

-- Added by Laurent Hayez
function pss_getView()
    return view
end


-- Variables for Firefly
math.randomseed(job.position * os.time())
phi = 0                                 -- phase
delta_min = 0.85
delta_max = 1.15
delta = delta_min + (delta_max - delta_min) * math.random()         -- cycle length
delta_natural = 1
omega_min = 1 / delta_max
omega_max = 1 / delta_min
omega = 1 / delta
omega_natural = 1 / delta_natural
epsilon = 0.05

active_thread_period = delta    -- period of active thread
update_phi_period = 0       -- period between two updates of phi
if delta < 1 then
    update_phi_period = delta / 5
else
    update_phi_period = 1 / (5 * delta)
end
offset = 0.1
max_time = 600              -- max time of execution
phase_advance = true

-- Firefly functions

-- g_plus
function g_plus(value)
    return math.max((math.sin(2 * math.pi * value)) / (2 * math.pi), 0)
end
-- g_minus
function g_minus(value)
    return -math.min((math.sin(2 * math.pi * value)) / (2 * math.pi), 0)
end

-- sendFlash
function firefly_sendFlash()
    local P = pss_getView()
    for i, node in ipairs(P) do
        rpc.call(node.peer, {"firefly_passiveThread", job.position})
    end
end

-- processFlash implemented with the adaptive Ermentrout model
function firefly_processFlash()
    if verbose then
        log:print("Old omega: ", omega)
    end
    omega = omega + epsilon * (omega_natural - omega) + g_plus(phi) * (omega_min - omega) +
            g_minus(phi) * (omega_max - omega)
    if verbose then
        log:print("New omega: ", omega)
    end
end

-- updatePhi
function firefly_updatePhi()
    if phi < 1 then
        phi = phi + omega * update_phi_period
        if verbose then
            print("New phi = ", phi)
        end
    else
        if verbose then
            log:print("PHI HAS REACHED THRESHOLD 1, FIRING FLASH")
        end
        events.fire("Flash!")
    end
end

-- Active thread
function firefly_activeThread()
    if phi >= 1 then
        phi = 0
        log:print("Node "..job.position.." emitted a flash. (phi was already at 1)")
        firefly_sendFlash()
    else
        local update_phi = events.periodic(firefly_updatePhi, update_phi_period)
        events.wait("Flash!")
	    phi = 0
        log:print("Node "..job.position.." emitted a flash.")
        --firefly_sendFlash()
        events.kill(update_phi)
    end
end

-- Passive thread
function firefly_passiveThread(sending_node_id)
    --log:print("Node "..job.position.." received a flash from node "..sending_node_id)
    firefly_processFlash()
end

-- Terminator function
function terminator()
    log:print("node "..job.position.." will quit in "..(max_time/60).." min")
    events.sleep(max_time)
    log:print("node "..job.position.." quitting...")
    os.exit()
end


-- main function
function main ()
    log:print("node "..job.position.." starting!")
    -- wait for all the nodes to be ready
    if on_cluster then
        events.sleep(120)
    end
    log:print("node "..job.position.." starting pss_init...")
    pss_init()
    --log:print("Waiting 120 sec for pss")
    --events.thread(terminator)
    --events.sleep(120)
    log:print("Start firefly")
    events.periodic(firefly_activeThread, active_thread_period)
end

events.thread(main)
events.run()
