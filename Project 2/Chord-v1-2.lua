--
-- Author:      Laurent Hayez
-- Date:        05 oct. 2015
-- Last Modif:  06 nov. 2015
-- Description: Basic implementation of the chord ring.
--              Adds 500 queries per node to see the average number of hops required to satisfy the query.
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
m = 30
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
-- closest node with bigger id
successor = nil
-- closest node with lower id
predecessor = nil
-- max time that the algorithm can run is 3 min
max_time = 180




------------------------------------------------
--- ===      Getters and Setters         === ---
------------------------------------------------

------------------------------------------------
function get_successor()
    return successor
end
------------------------------------------------
------------------------------------------------
function get_predecessor()
    return predecessor
end
------------------------------------------------
------------------------------------------------
function set_successor(node)
    successor = node
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
        print("Node ", job.position .. "\'s successor id: ", ' ', successor.id)
        events.sleep(2)
        rpc.call(successor, { "test" })
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
-- Note: The functionnment of is_between is the same for all kind of brackets. Example for '()':
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
            return (nb >= lower) or (nb <= upper)
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
-- ask node n to find id's predecessor
function find_predecessor(id)
    local n1 = n -- start searching with self
    local n1_successor = successor
    local i = 0

    while not is_between(id, n1.id, n1_successor.id, '(]') do
        n1 = n1_successor
        n1_successor = rpc.call(n1, { "get_successor" }) -- invoke get_successor() on n1
        i = i + 1
    end

    return n1, i
end

------------------------------------------------

------------------------------------------------
-- ask node n1 to find id's successor
function find_successor(id)
    local n1, _ = find_predecessor(id)
    local n1_successor = rpc.call(n1, { "get_successor" })
    return n1_successor
end

------------------------------------------------

------------------------------------------------
-- Initialize n's neighbours through n1
-- This function will be changed in future versions.
-- It will be split into three functions to implement chord's fingers.
function init_neighbours(n1)
    -- find (through node n1) the successor of your ID
    -- call find_successor on n1 with parameter (n.id+1)%2^m
    successor = rpc.call(n1, { "find_successor", (n.id + 1) % (2 ^ m) })
    -- call get_predecessor on node successor
    predecessor = rpc.call(successor, { "get_predecessor" })

    -- update the neighbours
    -- call set_predecessor(n) on successor
    rpc.call(successor, { "set_predecessor", n })
    -- call set_successor(n) on predecessor
    rpc.call(predecessor, { "set_successor", n })
end

------------------------------------------------

------------------------------------------------
-- n.join(n1): node n joins the network
-- n1 is an arbitrary node in the network
function join(n1)
    if n1 then
        init_neighbours(n1)
        -- n is the only node in the network
    else
        successor = n
        predecessor = n
    end
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
-- use hash function to be in the same space as the nodes
function generate_keys(n)
   if not on_cluster then
      file = io.open("Logs/log-test", "a+")
      for j = 1, n do
        rand_number = compute_hash(math.random(0, 2 ^ m))
        local _, i = find_predecessor(rand_number)
	   
	file:write("Number of hops:", i, "\n")
	file:write("Key to find:", rand_number, "\n")
	   
        print("Number of hops:", i)
        print("Key to find:", rand_number)
      end
      file:close()
   else
      for j = 1, n do
	 rand_number = compute_hash(math.random(0, 2 ^ m))
	 local _, i = find_predecessor(rand_number)
	 print("Number of hops:", i)
	 print("Key to find:", rand_number)
      end
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
        rpc.call(successor, { "test" })
    end

    if on_cluster then
        events.sleep(300)
        generate_keys(500)
    else
        events.sleep(30)
        generate_keys(10)
    end

    events.thread(terminator)
end
------------------------------------------------

-- execute the main function
events.thread(main)
events.run()




