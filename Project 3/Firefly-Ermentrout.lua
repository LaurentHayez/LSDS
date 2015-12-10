--[[
**
** Author:      Laurent Hayez
** Date:        03 dec 2015
** File:        Firefly implementation (adaptive Ermentrout model)
**
--]]

require("splay.base")
rpc = require("splay.urpc")
misc = require("splay.misc")
crypto = require("crypto")

-- addition to allow local run
if not job then
    -- can NOT be required in SPLAY deployments !
    local utils = require("splay.utils")
    if #arg < 2 then
        print("lua " .. arg[0] .. " my_position nb_nodes")
        os.exit()
    else
        local pos, total = tonumber(arg[1]), tonumber(arg[2])
        job = utils.generate_job(pos, total, 20001)
    end
    nodes = job.nodes()
else
    nodes = job.nodes
    on_cluster = true
end

rpc.server(job.me.port)


--[[
******************************************************************************
                           PEER SAMPLING PARAMETERS
******************************************************************************
]]

c = 10
exch = 5
S = 3
H = 2
SEL = "rand"
pss_active_thread_period = 20 -- period in seconds
pss_debug = false

--[[
******************************************************************************
                     PEER SAMPLING SERVICE: DO NOT MODIFY
******************************************************************************
]]

-- variables: peer sampling
view = {}

-- utilities
function print_table(t)
    log:print("[ (size "..#t..")")
    for i=1,#t do
        log:print("  "..i.." : ".."["..t[i].peer.ip..":"..t[i].peer.port.."] - age: "..t[i].age.." - id: "..t[i].id)
    end
    log:print("]")
end

function set_of_peers_to_string(v)
    ret = ""; for i=1,#v do	ret = ret..v[i].id.." , age="..v[i].age.."; " end
    return ret
end

function print_set_of_peers(v,message)
    if message then log:print(message) end
    log:print(set_of_peers_to_string(v))
end

function print_view(message)
    if message then log:print(message) end
    log:print("content of the view --> "..job.position..": "..set_of_peers_to_string(view))
end

-- peer sampling functions

function pss_selectPartner()
    if SEL == "rand" then return math.random(#view) end
    if SEL == "tail" then
        local ret_ind = -1 ; local ret_age = -1
        for i,p in pairs(view) do
            if (p.age > ret_age) then ret_ind = i end
        end
        assert (not (ret_ind == -1))
        return ret_ind
    end
end

function same_peer_but_different_ages(a,b)
    return a.peer.ip == b.peer.ip and a.peer.port == b.peer.port
end
function same_peer(a,b)
    return same_peer_but_different_ages(a,b) and a.age == b.age
end

function pss_selectToSend()
    -- create a new return buffer
    local toSend = {}
    -- append the local node view age 0
    table.insert(toSend,{peer={ip=job.me.ip,port=job.me.port},age=0,id=job.position})
    -- shuffle view
    view = misc.shuffle(view)
    -- move oldest H items to the end of the view
    --- 1. copy the view
    local tmp_view = misc.dup(view)
    --- 2. sort the items based on the age
    table.sort(tmp_view,function(a,b) return a.age < b.age end)
    --- 3. get the H largest aged elements from the tmp_view, remove them from the view
    ---    (we assume there are no duplicates in the view at this point!)
    ---    and put them at the end of the view
    for i=(#tmp_view-H+1),#tmp_view do
        local ind = -1
        for j=1,#view do
            if same_peer(tmp_view[i],view[j]) then ind=j; break end
        end
        assert (not (ind == -1))
        elem = table.remove(view,ind)
        view[#view+1] = elem
    end

    -- append the first exch-1 elements of view to toSend
    for i=1,(exch-1) do
        toSend[#toSend+1]=view[i]
    end

    return toSend
end

function pss_selectToKeep(received)
    if pss_debug then
        log:print("select to keep, node "..job.position)
        print_set_of_peers(received, "content of the received for "..job.position..": ")
        print_view()
    end
    -- concatenate the view and the received set of view items
    for j=1,#received do view[#view+1] = received[j] end

    -- remove duplicates from view
    -- note that we can't rely on sorting the table as we need its order later
    local i = 1
    while i < #view-1 do
        for j=i+1,#view do
            if same_peer_but_different_ages(view[i],view[j]) then
                -- delete the oldest
                if view[i].age < view[j].age then
                    table.remove(view,j)
                else
                    table.remove(view,i)
                end
                i = i - 1 -- we need to retest for i in case there is one more duplicate
                break
            end
        end
        i = i + 1
    end

    -- remove the min(H,#view-c) oldest items from view
    local o = math.min(H,#view-c)
    while o > 0 do
        -- brute force -- remove the oldest
        local oldest_index = -1
        local oldest_age = -1
        for i=1,#view do
            if oldest_age < view[i].age then
                oldest_age = view[i].age
                oldest_index = i
            end
        end
        assert (not (oldest_index == -1))
        table.remove(view,oldest_index)
        o = o - 1
    end

    -- remove the min(S,#view-c) head items from view
    o = math.min(S,#view-c)
    while o > 0 do
        table.remove(view,1) -- not optimal
        o = o - 1
    end

    -- in the case there still are too many peers in the view, remove at random
    while #view > c do table.remove(view,math.random(#view)) end

    assert (#view <= c)
end

no_passive_while_active_lock = events.lock()

function pss_passiveThread(from,buffer)
    no_passive_while_active_lock:lock()
    if pss_debug then
        print_view("passiveThread ("..job.position.."): entering")
        print_set_of_peers(buffer,"passiveThread ("..job.position.."): received from "..from)
    end
    local ret = pss_selectToSend()
    pss_selectToKeep(buffer)
    if pss_debug then
        print_view("passiveThread ("..job.position.."): after selectToKeep")
    end
    no_passive_while_active_lock:unlock()
    return ret
end

function pss_activeThread()
    -- take a lock to prevent being called as a passive thread while
    -- on an exchange with another peer
    no_passive_while_active_lock:lock()
    -- select a partner
    partner_ind = pss_selectPartner()
    partner = view[partner_ind]
    -- remove the partner from the view
    table.remove(view,partner_ind)
    -- select what to send to the partner
    buffer = pss_selectToSend()
    if pss_debug then
        print_set_of_peers(buffer,"activeThread ("..job.position.."): sending to "..partner.id)
    end
    -- send to the partner
    local ok, r = rpc.acall(partner.peer,{"pss_passiveThread", job.position, buffer},pss_active_thread_period/2)
    if ok then
        -- select what to keep etc.
        local received = r[1]
        if pss_debug then
            print_set_of_peers(received,"activeThread ("..job.position.."): received from "..partner.id)
        end
        pss_selectToKeep(received)
        if pss_debug then
            print_view("activeThread ("..job.position.."): after selectToKeep")
        end
    else
        -- peer not replying? remove it from view!
        if pss_debug then
            log:print("on peer ("..job.position..") peer "..partner.id.." did not respond -- removing it from the view")
        end
        table.remove(view,partner_ind)
    end
    -- all ages increment
    for _,v in ipairs(view) do
        v.age = v.age + 1
    end
    -- now, allow to have an incoming passive thread request
    no_passive_while_active_lock:unlock()
end

--[[
******************************************************************************
                            THE PEER SAMPLING API
******************************************************************************
]]

pss_initialized = false
function pss_init()
    -- ideally, would perform a random walk on an existing overlay
    -- but here we emerge from the void, so let's use the Splay provided peers
    -- note that we select randomly c+1 nodes so that if we have ourself in it,
    -- we avoid using it. Ages are taken randomly in [0..c] but could be
    -- 0 as well.
    if #nodes <= c then
        log:print("There are not enough nodes in the initial array from splay.")
        log:print("Use a network of at least "..(c+1).." nodes, and an initial array of type random with at least "..(c+1).." nodes")
        log:print("FATAL: exiting")
        os.exit()
    end
    if H + S > c/2 then
        log:print("Incorrect parameters H = "..H..", S = "..S..", c = "..c)
        log:print("H + S cannot be more than c/2")
        log:print("FATAL: exiting")
        os.exit()
    end
    local indexes = {}
    for i=1,#nodes do
        indexes[#indexes+1]=i
    end
    local selected_indexes = misc.random_pick(indexes,c+1)
    local i = 1
    while #view < c do
        if not (selected_indexes[i] == job.position) then
            view[#view+1] =
            {peer={ip=nodes[selected_indexes[i]].ip,port=nodes[selected_indexes[i]].port},age=0,id=selected_indexes[i]}
        end
        i=i+1
    end
    assert (#view == c)
    if pss_debug then
        print_view("initial view")
    end
    -- from that time on, we can use the view.
    pss_initialized = true

    math.randomseed(job.position*os.time())
    -- wait for all nodes to start up (conservative)
    events.sleep(2)
    -- desynchronize the nodes
    local desync_wait = (pss_active_thread_period * math.random())
    if pss_debug then
        log:print("waiting for "..desync_wait.." to desynchronize")
    end
    events.sleep(desync_wait)

    for i =1, 4 do
        pss_activeThread()
        events.sleep(pss_active_thread_period / 4)
    end
    events.periodic(pss_activeThread,pss_active_thread_period)
end

function pss_getPeer()
    if pss_initialized == false then
        log:print("Call to pss_getPeer() while the PSS is not initialized:")
        log:print("wait for some time before using the PSS!")
        log:print("FATAL. Exiting")
    end
    if #view == 0 then
        return nil
    end
    return view[math.random(#view)]
end

-- Added by Laurent Hayez
function pss_getView()
    return view
end


-- Variables for Firefly
math.randomseed(job.position * os.time())
phi = 0                                 -- phase
delta_min = 4.5
delta_max = 5.5
delta = delta_min + (delta_max - delta_min) * math.random()         -- cycle length
delta_natural = 5
omega_min = 1 / delta_max
omega_max = 1 / delta_min
omega = 1 / delta
omega_natural = 1 / delta_natural
epsilon = 0.01

active_thread_period = delta_max    -- period of active thread
update_phi_period = 0.01       -- period between two updates of phi
if delta < 1 then
    update_phi_period = delta_natural / 10
else
    update_phi_period = 1 / (10 * delta_natural)
end
max_time = 600              -- max time of execution
churn = true

-- Firefly functions

-- g_plus
function g_plus(value)
    return math.max((math.sin(2 * math.pi * value)) / (2 * math.pi), 0)
end
-- g_minus
function g_minus(value)
    return - (math.min((math.sin(2 * math.pi * value)) / (2 * math.pi), 0))
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
    omega = omega + epsilon * (omega_natural - omega) + g_plus(phi) * (omega_min - omega) + g_minus(phi) * (omega_max - omega)
end

-- updatePhi
function firefly_updatePhi()
    if phi < 1 then
        phi = phi + omega * update_phi_period
    else
        events.fire("Flash!")
        phi = 0
        events.thread(firefly_activeThread)
    end
end

-- Active thread
function firefly_activeThread()
    events.wait("Flash!")
    firefly_sendFlash()
    log:print("Node "..job.position.." emitted a flash.")
end

-- Passive thread
function firefly_passiveThread(sending_node_id)
    log:print("Node "..job.position.." received a flash from node "..sending_node_id)
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
    if churn then
        events.sleep(60)
    end
    log:print("node "..job.position.." starting!")
    -- wait for all the nodes to be ready
    if on_cluster and not churn then
        events.sleep(120)
    end
    log:print("node "..job.position.." starting pss_init...")
    pss_init()
    log:print("Waiting 120 sec for pss")
    if not churn then
        events.thread(terminator)
        events.sleep(120)
    end
    log:print("Start firefly")
    events.thread(firefly_activeThread, active_thread_period)
    events.periodic(firefly_updatePhi, update_phi_period)
end

events.thread(main)
events.run()
