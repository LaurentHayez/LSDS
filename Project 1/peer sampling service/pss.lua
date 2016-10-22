--[[
-- Author: Laurent Hayez
-- Date: 22 october 2015
-- Description: implementation of the Peer Sampling Service (PSS)
--              using gossip protocols.
--              It will be a push-pull implementation
--]]

--[[
require"splay.base"
rpc = require"splay.urpc"
misc = require("splay.misc")

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
  nodes = job.nodes
end

rpc.server(job.me.port)
--]]


-----------------------------------------------------------------------------
-- ================               VARIABLES              ================= --
-----------------------------------------------------------------------------
-- The view will contain 
--   - the age of the peer item
--   - a splay peer strucutre (ip, port) for rpcs on the peer
--   - the original position of the node.
-- Ex: view = {{peer = {ip = "192.168.1.1"}, age = 2, id = 1}, {peer = {ip = "192.168.1.2"}, age = 1, id = 2}}
-- Initially, the view is empty
view = {}
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- ================               CONSTANTS              ================= --
-----------------------------------------------------------------------------
-- c in the number of node in the view of one node.
c = 8
-- typically, exch = c/2
exch = c/2
-- H in an integer in {0, ..., exch-S} (healer parameter)
H = 0
-- S in an integer in {0, ..., exch-H} (shuffler parameter)
S = 4
-- SEL in {rand, tail} in the partner selection policy. Rand is random, and tail is the entry with the highest age.
SEL = 'rand'
-- Gossip period
gossip_period = 5
-- max time
max_time = 120
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- This function chooses n peers out of the view
function getPeers(n)
   peers_to_return = {}
   if n > #view then
      print("n was too big. Returning complete view.")
      for i, k in ipairs(view) do
	 table.insert(peers_to_return, k['peer'])
      end
      return peers_to_return
   else
      tmp = misc.random_pick(view, n)
      for i, k in ipairs(tmp) do
	 table.insert(peers_to_return, k['peer'])
      end
      return peers_to_return
   end
      
end
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- Utility function to print the view
function printTable(tab)
   for i, peers in ipairs(tab) do
      print(i, peers.peer.ip, peers.peer.port, peers.age, peers.id)
   end
   print("\n\n")
end
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- Utility to print the view at each peer, used for the ruby scripts
function viewContent()
   str = ""
   for i, peers in ipairs(view) do
      str = str..peers.id.." "
      --print(i, peers.peer.ip, peers.peer.port, peers.age, peers.id)
   end
   log:print("VIEW_CONTENT "..job.position.." "..str)
end
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- Utility function used to sort array by age (used for the view or k_oldest, to use the .age argument)
function sortByAge(a,b)
   return a.age < b.age
end
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- utility function that gets the k oldest nodes in the view
function getOldest(k)
   -- list to return
   local k_oldest = {}
   -- initialize list with k first value, not sorting it yet.
   for i = 1, k do table.insert(k_oldest, view[i]) end

   for i, peer in ipairs(view) do
      if i > k then -- peer is not in k_oldest <==> i > k (the k first are in k_oldest at initialisation, and the other peers are not)
	 for j, peer2 in ipairs(k_oldest) do
	    -- if the age of the current peer is greater than one peer in the k_oldest, replace peer2 by peer in k_oldest
	    if peer.age > peer2.age then
	       k_oldest[j] = peer
	       table.sort(k_oldest, sortByAge) -- need to sort it every time otherwise it may not be consistent (see footnote for details)
	       break -- need to break to get out of the loop (otherwise, for all P in k_oldest, P = peer, and we don't want that)
	    end
	 end
      end
   end
   return k_oldest
end
-----------------------------------------------------------------------------



-----------------------------------------------------------------------------
-- ================         FUNCTIONS OF THE PSS         ================= --
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
function selectPartner()
   -- Ensure that the selected peer is not itself
   if SEL == 'rand' then
      partner=nodes[math.random(1, #nodes)]
      if partner == nodes[job.position] then
	 selectPartner()
      end
      return partner
   -- Otherwise we select a peer from view with highest age
   else -- SEL = tail
      -- return oldest peer in the view (getOldest returns an array, but we want just the peer so we select first (and only) peer in the array)
      return getOldest(1)[1]
   end
end
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
function selectToSend()
   toSend = {}
   -- append self to view
   table.insert(toSend, {peer = job.me, age = 0, id = job.position})
   -- shuffle view
   view = misc.shuffle(view)   
   -- get H oldest items from the view
   h_oldest = getOldest(H)

   -- Move H oldest items to the end of the view
   for i, peer in ipairs(h_oldest) do
      for j, peer2 in ipairs(view) do
	 if peer == peer2 then
	    table.remove(view, j)
	    table.insert(view, peer)
	 end
      end
   end

   for i = 1, exch-1 do
      table.insert(toSend, view[i])
   end
   return toSend
end
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- received = buffer with (peer, age, id) entries
function selectToKeep(received) 

   view = misc.merge(view, received)
   --table.insert(view, received) -- line above should work better to concatenate both tables.

   -- Now we need to remove the duplicates from the view
   -- This is a trick to remove the right elements. Without it, if we delete an entry in the table, the next entry is skipped so 
   -- duplicates may rest. By getting the indexes to remove and remove them once we are sure which one to remove, we have consistency.
   local to_remove = {}
   for i, peers in ipairs(view) do -- for all peers in the view
      for j = i+1, #view do -- for all peers coming after peer
	 -- j<= #view is a small trick not to get an exception, because if some elements are removed, we will get an outOfBound Exception.
	 if j <= #view and view[i].id == view[j].id then -- compare if they are the same. If they are, keep most recent one.
	    if view[i].age >= view[j].age then
	       table.insert(to_remove, i)
	    else
	       table.insert(to_remove, j)
	    end
	 end -- if they are not the same, we don't do anything
      end
   end
   -- The removing is done now
   for i, k in ipairs(to_remove) do
      -- each time we remove an element, all is shifted to the left, so we have to shift the index of the element to remove by 1 to the left.
      -- Ex: suppose we have to_remove = {2, 6, 7}. We will remove the 2nd element of the view, then the 6-1=5th element of the NEW view 
      --     (without second entry), and then the 7-2 = 5th element of the NEW view (view without 2nd and 6th element).
      table.remove(view, k-(i-1))  
   end

   -- Now we remove min{H, view.size-c} oldest items from view.
   -- 1. Compute min.
   local min_H = math.min(H, #view-c)
   -- 2. Get min oldest items
   local min_oldest_items = getOldest(min_H)
   -- 3. Remove the min oldest items.
   -- We will use the same trick as before
   to_remove = {}
   for i, peer in ipairs(view) do -- for all peers in the view
      for j, peer2 in ipairs(min_oldest_items) do -- for all oldest peers
	 if view[i] == min_oldest_items[j] then -- if the current peer is in the oldest peers, add its index to to_remove table
	    table.insert(to_remove, i)
	 end
      end
   end
   for i, k in ipairs(to_remove) do
      table.remove(view, k-(i-1))  
   end
   
   -- Then we remove the min{S, view.size-c} head items from view
   -- 1. compute min
   local min_S = math.min(S, #view-c)
   -- 2. remove min_S head items
   for i = 1, min_S do
      table.remove(view, 1) -- We always remove the head of the new view (same old shift story..)
   end

   -- Finally we remove the max{0, view.size-c} random items from view
   -- 1. Compute max
   local max = math.max(0, #view-c)
   -- 2. remove the max random items
   -- if max < 1, we don't have to remove anything.
   if max >= 1 then
      for i = 1, max do
	 rand_number = math.random(1, #view) -- not the same old shift story here, as the length of the table is taken into account here.
	 table.remove(view, rand_number) 
      end
   end
end
-- End of selectToKeep function --
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
function activeThread()
   partner = selectPartner()
   buffer = selectToSend()
   received = rpc.call(partner, {"passiveThread", buffer})
   selectToKeep(received)
   for i, peer in ipairs(view) do
      peer.age = peer.age + 1
   end
end
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
function passiveThread(received)
   buffer = selectToSend()
   selectToKeep(received)
   return buffer
end
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
function terminator()
  events.sleep(max_time)
  viewContent()
  log:print("Closing node "..job.position) 
  os.exit()
end
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
function main_pss()
   -- To output the view of all the node (appoximately at the same time), we use another thread with a longer period than the
   -- gossip period. Also, to have this thread scheduled at the same time on all nodes, it is the first thing we create on each node
   -- Example of output: VIEW_CONTENT [peer id] [neighbor id]* ==> VIEW_CONTENT 21 12 78 1 2 78 3 22 43.

   -- events.periodic(viewContent, gossip_period*4)

   math.randomseed(job.position*os.time())
   -- wait for all nodes to start up (conservative)
   events.sleep(2)
   -- desynchronize the nodes
   local desync_wait = (gossip_period * math.random())
   
   log:print("waiting for "..desync_wait.." to desynchronize")
   events.sleep(desync_wait) 
   
   -- initialising view (excluding self)
   complete_view = {}
   copy_nodes = nodes
   table.remove(copy_nodes, job.position) -- removing self
   for i, v in ipairs(copy_nodes) do
      table.insert(complete_view, {peer = v, age = 0, id = i})  -- View of all the system, except self
   end
   c_rand_view = misc.random_pick(complete_view, c) -- pick c random nodes from the view, and append them to view
   for i, v in ipairs(c_rand_view) do
      table.insert(view, v)
   end 
   
   -- start gossiping!
   events.periodic(activeThread, gossip_period)
   -- end
   events.thread(terminator)
end 
-----------------------------------------------------------------------------
--[[
tab = misc.random_pick(nodes, c)
for i, v in ipairs(view) do
   table.insert(view, v)
end
printTable(view)
--]]

---[[
--events.thread(main)
--events.run()
--]]


















