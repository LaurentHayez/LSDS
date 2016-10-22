--[[
-- Author: Laurent Hayez
-- Date: 22 october 2015
-- Description: test file for selectToSend() function from the PSS.
--]]
require("splay.base")
misc = require("splay.misc")

view = {}
view[#view +1] = {peer = {ip = "127.0.0.1", port = 4255}, age = 4, id = 1}
view[#view +1] = {peer = {ip = "127.0.0.2", port = 4256}, age = 1, id = 2}
view[#view +1] = {peer = {ip = "127.0.0.3", port = 4232}, age = 30, id = 3}
view[#view +1] = {peer = {ip = "127.0.0.4", port = 1234}, age = 7, id = 4}
view[#view +1] = {peer = {ip = "127.0.0.5", port = 6432}, age = 15, id = 5}
view[#view +1] = {peer = {ip = "127.0.0.6", port = 42}, age = 10, id = 6}
view[#view +1] = {peer = {ip = "127.0.0.7", port = 879}, age = 2, id = 7}
view[#view +1] = {peer = {ip = "127.0.0.8", port = 401}, age = 9, id = 8}


c = 8
exch = c/2
H = 4
S = 2


-----------------------------------------------------------------------------
function printTable(tab)
   for i, peers in ipairs(tab) do
      print(i, peers.peer.ip, peers.peer.port, peers.age, peers.id)
   end
end
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- utility function that gets the k oldest nodes in the view
function getOldest(k)
   -- list to return
   local k_oldest = {}
   -- utility set, to see if the peer is in the k_oldest list already or not
   local utility_set = {}
   for i, peer in ipairs(view) do
      -- If the k_oldest list contains less than k elements, add some until it has k
      -- insert peer in utility_set, and set his appartenance to k_oldest to false
      utility_set.peer = false
      if #k_oldest < k then
	 table.insert(k_oldest, peer)
	 -- set appartenance to k_oldest to true
	 utility_set.peer = true
      else
	 for i, peer2 in ipairs(k_oldest) do
	    -- if the age of the current peer is greater than one peer in the k_oldest, and the peer is not already in it,
	    -- remove old peer from k_oldest, and insert new peer to it
	    -- set old peer appartenance to k oldest to false, and peer to true
	    if peer.age > peer2.age and (not utility_set.peer) then
	       table.remove(k_oldest, i)
	       table.insert(k_oldest, i, peer)
	       utility_set.peer = true
	       utility_set.peer2 = false
	    end
	 end
      end
   end
   return k_oldest
end
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
function selectToSend()
   toSend = {}
   -- append self to view
   --table.insert(toSend, {peer = job.me, age = 0, id = node_id})
   -- shuffle view
   print("View before shuffling:")
   printTable(view)
   print("\n\n")
   view = misc.shuffle(view)
   print("View after shuffling:")
   printTable(view)
   print("\n\n")
   
   -- get H oldest items from the view
   h_oldest = getOldest(H)
   print("H oldest peers: ")
   printTable(h_oldest)
   print("\n\n")
   -- Move H oldest items to the end of the view
   for i, peer in ipairs(h_oldest) do
      for j, peer2 in ipairs(view) do
	 if peer == peer2 then
	    table.remove(view, j)
	    table.insert(view, peer)
	 end
      end
   end
   print("View after moving oldest elements at the end:")
   printTable(view)
   print("\n\n")
   for i = 1, exch-1 do
      table.insert(toSend, view[i])
   end
   return toSend
end
-----------------------------------------------------------------------------

buf = selectToSend()
