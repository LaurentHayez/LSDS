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
   print("\n\n")
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
function selectToSend()
   toSend = {}
   -- append self to view
   -- table.insert(toSend, {peer = job.me, age = 0, id = node_id})
   -- shuffle view
   print("View before shuffling:")
   printTable(view)

   view = misc.shuffle(view)
   print("View after shuffling:")
   printTable(view)

   
   -- get H oldest items from the view
   h_oldest = getOldest(H)
   print("H oldest peers: ")
   printTable(h_oldest)

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

   for i = 1, exch-1 do
      table.insert(toSend, view[i])
   end
   return toSend
end
-----------------------------------------------------------------------------

buf = selectToSend()

peer = getOldest(1)
print(getOldest(1)[1].age)
