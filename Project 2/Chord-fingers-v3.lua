--
-- Author:      Laurent Hayez
-- Date:        06 oct. 2015
-- Last Modif:  21 nov. 2015
-- Description: Implementation of Chord with fingers
--              v2: stabilization for the fault-tolerant Chord Protocol.
--              v3: generate 500 keys per node on the cluster, and see how many queries are not satisfied
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
-- computes hash value for a given input string
function compute_hash(o)
    return tonumber(string.sub(crypto.evp.new("sha1"):digest(o), 1, m / 4), 16)
end

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

function get_successor()
   return finger[1].node
end

function get_predecessor()
    return predecessor
end

function set_successor(node)
   finger[1].node = node
end

function set_predecessor(node)
    predecessor = node
end

------------------------------------------------
--- ===        Chord functions         === ---
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

-- find_predecessor is split into two functions: closest_preceding_finger and find_predecessor
function closest_preceding_finger(id)
    for i = m, 1, -1 do
       if finger[i].node and is_between(finger[i].node.id, n.id, id, '()') then
            return finger[i].node
        end
    end
    -- Addition
    return n
end

function find_predecessor(id)
    local n1 = n -- start searching with self
    local n1_successor = get_successor()
    local i = 0

    -- while successor is not nil and id not in (n1.id, successor.id]
    while n1_successor and not is_between(id, n1.id, n1_successor.id, '(]') do
        n1 = rpc.call(n1, {"closest_preceding_finger", id}) 
        n1_successor = rpc.call(n1, { "get_successor" }) -- invoke get_successor() on n1
        i = i + 1
    end

    return n1, i
end

-- ask node n1 to find id's successor
function find_successor(id)
    local n1, _ = find_predecessor(id)
    local n1_successor = rpc.call(n1, { "get_successor" })
    return n1_successor
end

function fix_fingers()
   i = math.random(2,m)
   finger[i].node = find_successor(finger[i].start)
end

function notify(n1)
   if not predecessor or is_between(n1.id, predecessor.id, n.id, '()') then
      predecessor = n1
   end
end

function stabilize()
   local x = rpc.call(get_successor(), { "get_predecessor" })
   -- Addition of the x condition
   if x and is_between(x.id, n.id, get_successor().id, '()') then
      set_successor(x)
   end
   rpc.call(get_successor(), { "notify", n })
end

function join(n1)
   if n1 then
      predecessor = nil
      set_successor(rpc.call(n1, {"find_successor", n.id}))
   else
      predecessor = n
      set_successor(n)
   end
end

--checks if fingers are stale references or not
function check_fingers()
   for i = 1, m do
      if finger[i].node and not rpc.ping(finger[i].node) then
	 print("Stale reference to finger["..i.."]")
      end
   end
end

-- function to generate n random keys per node
function generate_keys(n)
    for j = 1, n do
        rand_number = math.random(0, 2 ^ m)
        local pred, i = find_predecessor(rand_number)
	 print("Key to find:", rand_number)
	if pred and rpc.call(pred, {"get_successor"}) then
	   print("Number of hops:", i)
	   print("Key "..rand_number.." found")
	else
	   print("Failed to find the key "..rand_number)
	end
    end
end

------------------------------------------------

function main()

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
    
    events.periodic(stabilize, 10)
    events.periodic(fix_fingers, 20)
    events.periodic(check_fingers, 20)


    if on_cluster then
       -- wait 4 minutes before starting to genereate keys, so that the ring is more or less constructed
       events.sleep(240)
       generate_keys(500)
    else
       generate_keys(10)
    end
end
------------------------------------------------

-- execute the main function
events.thread(main)
events.run()

