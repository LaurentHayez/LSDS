--[[
**
** Author:      Laurent Hayez
** Date:        03 dec 2015
** File:        Firefly implementation (skeleton)
**
--]]

-- Variables for Firefly
phi = 1                     -- phase
delta = 1                   -- cycle length
active_thead_period = delta     -- period of active thread
update_phi_init = false
update_phi_period = 0.01       -- period between two updates of phi
if delta < 1 then
    update_phi_period = delta / 10
else
    update_phi_period = 1 / (10 * delta)
end

-- Firefly functions

-- sendFlash
function firefly_sendFlash()
    local P = pss_getView()
    for i, node in ipairs(P) do
        rpc.call(node.peer, {"firefly_passiveThread", job.position})
    end
end

-- processFlash
function firefly_processFlash()
    -- depends of the implementation
end

-- updatePhi
function firefly_updatePhi()
    if phi < 1 then
        phi = phi + (1 / delta) * update_phi_period
    else
        events.fire("Flash!")
        phi = 0
    end
end

-- Active thread
function firefly_activeThread()
    if not update_phi_init then
        update_phi_init = true
        events.periodic(firefly_updatePhi, update_phi_period)
    end
    events.wait("Flash!")
    firefly_sendFlash()
    log:print("Node "..job.position.." emitted a flash.")
end

-- Passive thread
function firefly_passiveThread(sending_node_id)
    log:print("Node "..job.position.." received a flash from node "..sending_node_id)
    firefly_processFlash()
end
