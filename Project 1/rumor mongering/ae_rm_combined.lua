--[[
-- Author: Laurent Hayez
-- Date: 21 october 2015
-- Desc: Anti-entropy and rumor mongering mechanisms combined
--]]

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

-- constants
rumor_mongering_period = 5
max_time = 120 -- we do not want to run forever ...
HTL = 2
f = 3

-- variables
infected = "no"
current_cycle = 0
buffered = false -- do I have buffered messages?
buffered_h = nil -- hops-to-live value for buffered messages


-----------------------------------------------------------------------------
function rm_notify(h)
   -- invoked by a remote node to infect the current node
   -- buffer only if (1) not infected or (2) rumor with larger HTL
  log:print("node "..job.position.." ("..infected..") was notified with hops "..h.." (HTL="..HTL..")")

  -- TODO: infect if necessary
  if infected == "yes" then
     log:print(os.date("%X").." duplicate_received")
  else
     infected = "yes"
     log:print("i_am_infected")
  end

  if (not buffered) or (bufferef and ((h-1) > buffered_h)) then
     buffered = true
     buffered_h = h-1
  end

  if (h < HTL) or (buffered and ((h + 1) < buffered_h)) then
    buffered = true
    buffered_h = h + 1
  end
end
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
function rm_activeThread()
  current_cycle = current_cycle + 1

  -- do I have to send something to someone?
  if buffered then
    log:print(job.position.." proceeds to forwarding to "..f.." peers")

    -- TODO: select f destination nodes and notify each of
    -- them via a rpc to notify(buffered_h)
    -- select nodes with misc.random_pick (excluding self from the random pick)
    copy_nodes = nodes
    table.remove(copy_nodes, job.position)
    selected_nodes = misc.random_pick(copy_nodes, f)

    -- sending rpc to all nodes
    -- we invoke the method rm_notify(h) with h=buffered_h
    for i, node in ipairs(selected_nodes) do
       rpc.call(node, {"rm_notify", buffered_h})
    end
    
    buffered = false
    buffered_h = nil
  end
end
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- ================ FUNCTIONS FOR ANTI ENTROPY MECHANISM ================= --
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
function selectPartner()
   partner=nodes[math.random(1, #nodes)]
   if partner == nodes[job.position] then
      selectPartner()
   end
   return partner
end
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
function selectToSend()
  return infected
end
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
function selectToKeep(received)
  infect=nil
  if infected=="no"and received=="no" then
    infect = "no"
  else
    infect="yes"
  end
  return infect
end
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
function receive(state)
   old_infected = infected
   infected=selectToKeep(state)
   if infected=="yes" and old_infected=="no" then
      log:print("i_am_infected")
   end
   return infected
end
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
function gossip()
   gossip_partner=selectPartner()
   received = rpc.call(gossip_partner, {"receive", selectToSend()})
   receive(received)
end
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
function terminator()
  events.sleep(max_time)
  log:print("FINAL: node "..job.position.." "..infected) 
  os.exit()
end
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
function main()
  math.randomseed(job.position*os.time())
  -- wait for all nodes to start up (conservative)
  events.sleep(2)
  -- desynchronize the nodes
  local desync_wait = (rumor_mongering_period * math.random())
  -- the first node is the source and is infected since the beginning
  if job.position == 1 then
     log:print(os.date("%X"))
     infected = "yes"
     buffered = true
     buffered_h = 0
     log:print("i_am_infected")
     desync_wait = 0
  end
  log:print("waiting for "..desync_wait.." to desynchronize")
  events.sleep(desync_wait)  
  
  -- start gossiping!
  -- while not all_infected() do 
  events.periodic(rm_activeThread, rumor_mongering_period)
  events.periodic(gossip, rumor_mongering_period)
  -- end
  events.thread(terminator)
end 
----------------------------------------------------------------------------- 

events.thread(main)
events.run()
