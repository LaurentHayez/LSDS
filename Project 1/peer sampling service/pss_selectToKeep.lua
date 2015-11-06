--[[
-- Author: Laurent Hayez
-- Date: 22 october 2015
-- Description: test of selectToKeep() function from PSS

   -- TODO: add prints to selectToKeep() and test it.
--]]


require"splay.base"
misc = require"splay.misc"



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
view[#view +1] = {peer = {ip = "127.0.0.1", port = 4255}, age = 4, id = 1}
view[#view +1] = {peer = {ip = "127.0.0.2", port = 4256}, age = 1, id = 2}
view[#view +1] = {peer = {ip = "127.0.0.3", port = 4232}, age = 30, id = 3}
view[#view +1] = {peer = {ip = "127.0.0.4", port = 1234}, age = 7, id = 4}
view[#view +1] = {peer = {ip = "127.0.0.5", port = 6432}, age = 15, id = 5}
view[#view +1] = {peer = {ip = "127.0.0.6", port = 42}, age = 10, id = 6}
view[#view +1] = {peer = {ip = "127.0.0.7", port = 879}, age = 2, id = 7}
view[#view +1] = {peer = {ip = "127.0.0.8", port = 401}, age = 9, id = 8}

view2 = {}
view2[#view2 +1] = {peer = {ip = "128.0.0.1", port = 4255}, age = 4, id = 9}
view2[#view2 +1] = {peer = {ip = "127.154.0.2", port = 4256}, age = 1, id = 10}
view2[#view2 +1] = {peer = {ip = "127.0.0.3", port = 4232}, age = 12, id = 3}
view2[#view2 +1] = {peer = {ip = "127.0.0.4", port = 1234}, age = 1, id = 4}
view2[#view2 +1] = {peer = {ip = "127.0.0.5", port = 6432}, age = 15, id = 5}
view2[#view2 +1] = {peer = {ip = "192.168.1.1", port = 42}, age = 10, id = 11}
view2[#view2 +1] = {peer = {ip = "178.0.0.7", port = 879}, age = 2, id = 12}
view2[#view2 +1] = {peer = {ip = "124.0.0.8", port = 401}, age = 9, id = 13}
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- ================               CONSTANTS              ================= --
-----------------------------------------------------------------------------
-- c in the number of node in the view of one node.
c = 8
-- typically, exch = c/2
exch = c/2
-- H in an integer in {0, ..., exch-S} (healer parameter)
H = 4
-- S in an integer in {0, ..., exch-H} (shuffler parameter)
S = 2
-- SEL in {rand, tail} in the partner selection policy. Rand is random, and tail is the entry with the highest age.
SEL = 'rand'
-----------------------------------------------------------------------------

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
-- received = buffer with (peer, age, id) entries
function selectToKeep(received) 

   print("View before appending the received view:")
   printTable(view)

   print("View received:")
   printTable(received)
   view = misc.merge(view, received)
   --table.insert(view, received) -- line above should work better to concatenate both tables.

   print("View after appending received view:")
   printTable(view)

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

   print("View after removing duplicates:")
   printTable(view)

   -- Now we remove min{H, view.size-c} oldest items from view.
   -- 1. Compute min.
   local min_H = math.min(H, #view-c)
   -- 2. Get min oldest items
   local min_oldest_items = getOldest(min_H)
   print("min_oldest_items:")
   printTable(min_oldest_items)
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

   print("View after removing "..H.." oldest items:")
   printTable(view)
   
   -- Then we remove the min{S, view.size-c} head items from view
   -- 1. compute min
   local min_S = math.min(S, #view-c)
   -- 2. remove min_S head items
   for i = 1, min_S do
      table.remove(view, 1) -- We always remove the head of the new view (same old shift story..)
   end
   print("View after removing " ..S.. " S min(S, #view-c) head items:")
   printTable(view)

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

   print("View after removing " .. max .. " random items:")
   printTable(view)

end
-- End of selectToKeep function --
-----------------------------------------------------------------------------

selectToKeep(view2)



--[[ Footnote 
   1. Example of non-consistent k_oldest without sorting.
      Suppose we have k=2 and (simplified) view={p1=3, p2=6, p3=8, p4=1, p5=10} where the structure is peer=age.
      At first, we have k_oldest = {p1, p2}
      We start looping, p1 and p2 don't satisfy the first condition, but p3 does (p3 is not in k_oldest). Thus i = 3, peer = p3
         j = 1, peer2 = p1 ==> p3.age > p1.age ==> k_oldest = {p3, p2}, break
      i = 4, peer = p4,
         j = 1, peer2 = p3, ==> p4.age < p3.age ==> break, j = 2, peer2 = p2 ==> p4.age < p2.age ==> break.
      i = 5, peer = p5,
         j = 1, peer2 = p3, ==> p5.age > p3.age ==> k_oldest = {p5, p2}, break 
      return k_oldest
      But this is not consistent!
      Even if instead of repleacing peer2 with peer, we appended it at the end of k_oldest, we would then have
      i = 3, peer = p3 ==> ... ==> k_oldest = {p2, p3}
      i = 4, peer = p4 ==> ... ==> k_oldest = {p2, p3}
      i = 5, peer = p5 ==> ... ==> k_oldest = {p3, p5}  (==> ages = (8, 10))
      Now suppose we have a peer p6 in our view with age 9 and a peer p7 with age 11, then
      i = 6, peer = p6 ==> ... ==> k_oldest = {p5, p6}   (==> ages = (10, 9))
      i = 7, peer = p7 ==> ... ==> k_oldest = {p6, p7} (==> ages = (9, 11))
      Thus still not consistent (this is actually where I realized I had to sort k_oldest for my algorithm to work :) )
   Of course there are other ways to solve it rather than sorting k_oldest everytime we append a new element, but the k_oldest array is 
   always nearly sorted, so a bubble sort on it would be pretty efficient (I used would, because I don't know which algorithm lua uses to 
   sort the tables).
--]]
