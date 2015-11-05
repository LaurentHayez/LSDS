--
-- Created by IntelliJ IDEA.
-- User: splay
-- Date: 10/29/15
-- Time: 4:58 PM
-- To change this template use File | Settings | File Templates.
--

---[[
require("splay.base")
rpc = require("splay.urpc")
misc = require("splay.misc")
crypto = require("crypto")

-- addition to allow local run
if not job then
    -- can NOT be required in SPLAY deployments !
    local utils = require("splay.utils")
    if #arg < 2 then
        print("lua "..arg[0].." my_position nb_nodes")
        os.exit()
    else
        local pos, total = tonumber(arg[1]), tonumber(arg[2])
        job = utils.generate_job(pos, total, 20001)
    end
    nodes = job.nodes()
else
   nodes = job.nodes()
end

rpc.server(job.me.port)
--]]

-- length of ID in bits
m = 32
------------------------------------------------
-- computes hash value for a given input string
function compute_hash(o)
    return tonumber(string.sub(crypto.evp.new("sha1"):digest(o), 1, m / 4),16)
end

------------------------------------------------

------------------------------------------------
---   ===            Variables           === ---
------------------------------------------------
-- node itself
n = job.me
-- random position on the ring
-- it is the hash of the concatenation of the node's ip and port
n.id = compute_hash(n.ip..n.port)
print("Node "..job.position.." id: "..n.id)
-- closest node with bigger id
successor = nil
-- closest node with lower id
predecessor = nil
-- max time that the algorithm can run is 3 min
max_time = 180




------------------------------------------------
---   ===      Getters and Setters       === ---
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

-----------------------------------------------------------------------------
var = false
function test()
    if var == false then
       var = true
       print("Node ", job.position.."\'s successor id: ", ' ', successor.id)
       events.sleep(2)
       rpc.call(successor, {"test"})
    end
end
-----------------------------------------------------------------------------


------------------------------------------------
---   ===        Chord functions         === ---
------------------------------------------------

------------------------------------------------
-- Utility function to check if c is in interval [a,b].
-- Intervals can be (), (], [), [].
-- A call to this function is for example: is_between(5, 4, 6, '(]')
-- Returns true or false
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




function isInRange(e, from, to)
   if from < to then
      return (e > from) and (e <= to) -- => (from, to]
   else
      return (e > from) or (e <= to)  -- => (from, to] over circle nPrime, also handles starting condition from == to
   end
end



------------------------------------------------
-- ask node n to find id's predecessor
function find_predecessor(id)

    local n1 = n -- start searching with self
    local n1_successor = successor
    -- important: n1_successor may have smaller ID than n1
    -- we check if the interval is not empty (otherwise we discard the solution) and then we apply the condition
    -- that id is not in the interval (n1.id, n1_successor.id].
    print("id: ", id, "(", n1.id, n1_successor.id,"]")
    --while (not interval_is_empty(n1.id, n1_successor.id, '(]')) and (not is_between(id, n1.id, n1_successor.id, '(]')) do
    while not is_between(id, n1.id, n1_successor.id, '(]')  do
        n1 = n1_successor
        n1_successor = rpc.call(n1, {"get_successor"}) -- invoke get_successor() on n1
	print("id: ", id, "(", n1.id, n1_successor.id,"]")
    end
    --print("Node "..job.position.."\'s successor id: "..successor.id)
    --rpc.call(successor, {"test", n.id})
    return n1
end
------------------------------------------------
 
------------------------------------------------
-- ask node n1 to find id's successor
function find_successor(id)
    local n1 = find_predecessor(id)
    local n1_successor = rpc.call(n1, {"get_successor"})
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
    successor = rpc.call(n1, {"find_successor", (n.id+1)%(2^m)})
    -- call get_predecessor on node successor
    predecessor = rpc.call(successor, {"get_predecessor"})

    -- update the neighbours
    -- call set_predecessor(n) on successor
    rpc.call(successor, {"set_predecessor", n})
    -- call set_successor(n) on predecessor
    rpc.call(predecessor, {"set_successor", n})
end
------------------------------------------------

------------------------------------------------
-- n.join(n1): node n joins the network
-- n1 is an arbitrary node in the network
function join(n1)
    if n1 then
        init_neighbours(n1)
	print("Node "..job.position.." id :"..n.id)
	print("Node "..job.position.." successor id :"..successor.id)
	print("Node "..job.position.." predecessor id :"..predecessor.id)
    -- n is the only node in the network
    else
        successor = n
        predecessor = n
    end
end
------------------------------------------------



-----------------------------------------------------------------------------
function terminator()
    events.sleep(max_time)
    os.exit()
end
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
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
        math.randomseed(job.position*os.time())
        -- wait a random time in [0,8) seconds to join the ring (=> total waited <= 10)
        wait_time = math.random()*8
        events.sleep(wait_time)
	--events.sleep(job.position)
	print("Node " .. job.position .. " joins the ring after waiting " .. (wait_time+2) .. " seconds.\n")
        join(n0)
    end

    if job.position == 1 then
       events.sleep(15)
       rpc.call(successor, {"test"})
    end

   -- print("\n\nNode "..job.position.."\'s id: "..n.id)
   -- print("Node "..job.position.."\'s successor id: "..successor.id)
   -- print("Node "..job.position.."\'s predecessor id: "..predecessor.id.."\n")

    events.thread(terminator)
end
-----------------------------------------------------------------------------

-- execute the main function
events.thread(main)
events.run()




