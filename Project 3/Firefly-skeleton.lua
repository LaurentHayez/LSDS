--[[
**
** Author:      Laurent Hayez
** Date:        03 dec 2015
** File:        Firefly implementation (skeleton)
**
--]]

-- Variables for Firefly
phi = 1             -- phase
delta = 1           -- cycle length

-- Firefly functions
-- processFlash will vary in the different implementations
function firefly_processFlash()
    return true
end

-- Active thread
function firefly_activeThread()
    events.sleep(delta)         -- wait until phi = 1
    P = {}
    for i = 1, 10 do
        P[i] = pss_getPeer()
    end
    for peer in ipairs(P) do
        rpc.call(peer, {"passiveThread"})
    end
end

-- Passive thread
function firefly_passiveThread()
    processFlash()
end

