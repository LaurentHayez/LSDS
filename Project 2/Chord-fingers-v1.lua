--
-- Author:      Laurent Hayez
-- Date:        06 oct. 2015
-- Last Modif:  06 nov. 2015
-- Description: Implementation of Chord with fingers
--

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


-- length of ID in bits
m = 28
------------------------------------------------
-- computes hash value for a given input string
function compute_hash(o)
    return tonumber(string.sub(crypto.evp.new("sha1"):digest(o), 1, m / 4), 16)
end
------------------------------------------------

------------------------------------------------
--- ===            Variables             === ---
------------------------------------------------
-- node itself
n = job.me
-- random position on the ring
-- it is the hash of the concatenation of the node's ip and port
n.id = compute_hash(n.ip .. n.port)
print("Node " .. job.position .. " id: " .. n.id)
finger = {}
-- fingers is table of know nodes (at initialization, it only knows itself, 
-- start = n.id+2^(k-1) mod 2^m, 1 <= k <= m thus start = n.id + 1 % 2^m)
for i = 1, m do
   finger[i] = {node = nil, start = (n.id + 2^(i-1)) % 2^m}
end
finger[1].node = n

-- closest node with lower id
predecessor = nil
-- max time that the algorithm can run is 3 min
max_time = 180




------------------------------------------------
--- ===      Getters and Setters         === ---
------------------------------------------------

------------------------------------------------
function get_successor()
   return finger[1].node
end
------------------------------------------------
------------------------------------------------
function get_predecessor()
    return predecessor
end
------------------------------------------------
------------------------------------------------
function set_successor(node)
   finger[1].node = node
end
------------------------------------------------
------------------------------------------------
function set_predecessor(node)
    predecessor = node
end
------------------------------------------------


------------------------------------------------
-- Utility function that tests if the ring is correctly constructed
var = false
function test()
    if var == false then
        var = true
        print("Node ", job.position .. "\'s successor id: ", ' ', get_successor().id)
        events.sleep(2)
        rpc.call(get_successor(), { "test" })
    end
end

------------------------------------------------


------------------------------------------------
--- ===        Chord functions         === ---
------------------------------------------------

------------------------------------------------
------------------------------------------------
-- Utility function to check if c is in interval [a,b].
-- Intervals can be (), (], [), [].
-- A call to this function is for example: is_between(5, 4, 6, '(]')
-- Returns true or false
-- -----------------------
-- Note: The functionnment of is_between is the same for all kind of brackets. Example for '()':
-- We are on a ring, so if the lower bound of the interval is smaller than the upper bound, we
-- simply check if the id is in (lower, upper).
-- if upper < lower, the id may still be in the intervall, that simply means that 2^m is in the interval,
-- and as we work modulo 2^m, upper is smaller, but modulo 2^m only. Think of a clock, where the hand of
-- the clock might be between (11, 1). This interval is not empty. Thus in the case where upper <= lower,
-- we have to check if id >= lower, or id <= upper. In the previous example, that means we check if the
-- hand of the clock is between [11,12] or between [0, 1].
-- -----------------------
function is_between(nb, lower, upper, brackets)
    if brackets == '()' then
        if lower < upper then
            return (nb > lower) and (nb < upper)
        else
            return (nb > lower) or (nb < upper)
        end
    elseif brackets == '(]' then
        if lower < upper then
            return (nb > lower) and (nb <= upper)
        else
            return (nb > lower) or (nb <= upper)
        end
    elseif brackets == '[)' then
        if lower < upper then
            return (nb >= lower) and (nb < upper)
        else
            return (nb >= lower) or (nb < upper)
        end
    else
        if lower < upper then
            return (nb >= lower) and (nb <= upper)
        else
            return (nb >= lower) or (nb <= upper)
        end
    end
end

------------------------------------------------

------------------------------------------------
-- find_predecessor is split into two functions: closest_preceding_finger and find_predecessor
function closest_preceding_finger(id)
    for i = m, 1, -1 do
        if is_between(finger[i].node.id, n.id, id, '()') then
            return finger[i].node
        end
    end
end
------------------------------------------------
function find_predecessor(id)
    local n1 = n -- start searching with self
    local n1_successor = get_successor()
    local i = 0
    --print("Id: ", id, "( n1.id=", n1.id, "n1_successor.id = ", n1_successor.id, "]")
    while not is_between(id, n1.id, n1_successor.id, '(]') do
       
        n1 = rpc.call(n1, {"closest_preceding_finger", id})
        n1_successor = rpc.call(n1, { "get_successor" }) -- invoke get_successor() on n1
        i = i + 1
    end

    return n1, i
end

------------------------------------------------

------------------------------------------------
-- ask node n1 to find id's successor
function find_successor(id)
   --print("\t\tStart find_successor")
    local n1, _ = find_predecessor(id)
    local n1_successor = rpc.call(n1, { "get_successor" })
    --print("\t\tEnd find_successor")
    return n1_successor
end

------------------------------------------------

------------------------------------------------
-- Instead of init_neighbours, we have init_finger_table, update_finger_table and update_others
function init_finger_table(n1)
   --print("\tStart init_finger_table")
    --finger[1].node = rpc.call(n1, { "find_successor", finger[1].start })
    -- no need for rpc because we are on the same node (?)
   --print("Node "..job.position.." old finger[1].node.id = "..finger[1].node.id)
    finger[1].node = rpc.call(n1, {"find_successor", finger[1].start})
    --print("Node "..job.position.." new finger[1].node.id = "..finger[1].node.id)
    predecessor = rpc.call(get_successor(), { "get_predecessor" })
    for i = 1, m-1 do
    --    print(unpack(finger[i+1]))
        if is_between(finger[i+1].start, n.id, finger[i].node.id, '[)') then
            finger[i+1].node = finger[i].node
        else
            finger[i+1].node = rpc.call(n1, { "find_successor", finger[i+1].start })
        end
    end
    --print("\tEnd init_finger_table")
end
------------------------------------------------
function update_finger_table(s,i)
    if finger[i].start ~= finger[i].node.id and is_between(s.id, finger[i].start, finger[i].node.id, '[)') then
        finger[i].node = s
        p = predecessor
        rpc.call(p, { "update_finger_table", s,i })
    end
end
------------------------------------------------
function update_others()
    rpc.call(get_successor(), { "set_predecessor", n })
    for i = 1, m do
        p = find_predecessor((n.id+1-2^(i-1)) % 2 ^ m)
	--print("p id: "..p.id)
        rpc.call(p, { "update_finger_table", n, i })
    end
end
------------------------------------------------

------------------------------------------------
-- n.join(n1): node n joins the network
-- n1 is an arbitrary node in the network
function join(n1)
   --print("Start join")
    if n1 then
       init_finger_table(n1)
       predecessor = rpc.call(get_successor(), {"get_predecessor"})
       print("Let\'s go to update_others()")
       update_others()
        -- n is the only node in the network
    else
        for i = 1, m do
	   -- have to initialize an empty array for finger[i], otherwise lua does not understand what I want to do
	   if i ~= 1 then
	      finger[i] = {}
	   end
	   finger[i].node = n
	   finger[i].start = (n.id + 2^(i-1)) % 2^m
        end
        predecessor = n
    end
    --print("End join")
end
------------------------------------------------



------------------------------------------------
function terminator()
    events.sleep(max_time)
    os.exit()
end
------------------------------------------------

------------------------------------------------
-- function to generate n random keys per node
function generate_keys(n)
    for j = 1, n do
        rand_number = math.random(0, 2 ^ m)
        local _, i = find_predecessor(rand_number)
        print("Number of hops:", i)
        print("Key to find:", rand_number)
    end
end
------------------------------------------------

------------------------------------------------
function main()

    if on_cluster then
        -- sleep 10 minutes so that all the nodes on the cluster are ready.
        events.sleep(600)
    end

    -- This is the first node that every other node knows
    n0 = nodes[1]
    -- If n is the first node, it immediately joins the ring
    if job.position == 1 then
        -- The first node creates the Ring
        print("Node 1 is creating the ring...\n")
        join(nil)
        -- otherwise, wait a random time between [0,10) seconds to join the ring
    else
        -- Wait 2 seconds for the ring to be initialized
        events.sleep(2)
        -- Generate a random seed
        math.randomseed(job.position * os.time())
        -- wait a random time in [0,8) seconds to join the ring (=> total waited <= 10)
        wait_time = math.random() * 8
        events.sleep(wait_time)
        print("Node " .. job.position .. " joins the ring after waiting " .. (wait_time + 2) .. " seconds.\n")
        join(n0)
    end

    if on_cluster then
        -- wait 3 minutes for latency.
        events.sleep(180)
    end

    if job.position == 1 then
        events.sleep(15)
        rpc.call(get_successor(), { "test" })
    end
    
    --print("Node "..job.position.." id: ", n.id)
    --print("Node "..job.position.." successor: ", get_successor().id)
    --print("Node "..job.position.." predecessor: ", predecessor.id)

    --[[
    if on_cluster then
        events.sleep(300)
        generate_keys(500)
    else
        events.sleep(30)
        generate_keys(10)
    end
    --]]

    events.thread(terminator)
end
------------------------------------------------

-- execute the main function
events.thread(main)
events.run()






