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
active_thead_period = 2     -- period of active thread
update_phi_period = 0       -- period between two updates of phi
if delta < 1 then
    update_phi_period = (active_thead_period / 5) * delta
else
    update_phi_period = active_thead_period / (5 * delta)
end

-- Firefly functions

-- sendFlash
function firefly_sendFlash()
    local P = {}
    P = pss_getView()
    for i, peer in ipairs(P) do
        rpc.call(peer, {"firefly_passiveThread"})
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
    end
end

-- Active thread
function firefly_activeThread()
    if phi >= 1 then
        firefly_sendFlash()
    else
        local update_phi = events.periodic(firefly_updatePhi, update_phi_period)
        events.wait("Flash!")
        log:print("Flash emitted.")
        firefly_sendFlash()
        events.kill(update_phi)
    end
end

-- Passive thread
function firefly_passiveThread()
    log:print("Flash received.")
    processFlash()
end
