--[[
---- Author: Laurent Hayez
---- Date: 01 october 2015
---- File: anti_entropy.lua
----       implements the anti entropy protocol seen in class
--]]

require"splay.base"
rpc = require"splay.urpc"
-- to use TCP RPC, replace previous by the following line
-- rpc = require"splay.rpc"

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
  nodes=job.nodes()
else
  nodes=job.nodes
end

rpc.server(job.me.port)

-- constants
anti_entropy_period = 5 -- gossip every 20 seconds
max_time = 120 -- we do not want to run forever ...

-- variables
infected = "no"
current_cycle = 0

-- TODO here insert your functions from the gossip framework
function selectPartner()
	partner=nodes[math.random(1, #nodes)]
	if partner == nodes[job.position] then
	  selectPartner()
	end
  return partner
end

function selectToSend()
  return infected
end

function selectToKeep(received)
  infect=nil
  if infected=="no"and received=="no" then
    infect = "no"
  else
    infect="yes"
  end
  return infect
end

function receive(state)
	old_infected = infected
	infected=selectToKeep(state)
	if infected=="yes" and old_infected=="no" then
	   log:print("i_am_infected")
	end
	return infected
end

function gossip()
	gossip_partner=selectPartner()
	received = rpc.call(gossip_partner, {"receive", selectToSend()})
	receive(received)
end
--
--
--
--
--

-- helping functions
function terminator()
  events.sleep(max_time)
  log:print("FINAL: node "..job.position.." "..infected) 
  os.exit()
end

function main()
  -- init random number generator
  math.randomseed(job.position*os.time())
  -- wait for all nodes to start up (conservative)
  events.sleep(2)
  -- desynchronize the nodes
  local desync_wait = (anti_entropy_period * math.random())
  -- the first node is the source and is infected since the beginning
  if job.position == 1 then
    infected = "yes"
    log:print("i_am_infected")
    desync_wait = 0
  end
  log:print("waiting for "..desync_wait.." to desynchronize")
  events.sleep(desync_wait)  
  
  -- TODO: here, you should insert the command 
  --       that starts the gossiping activity
  -- TODO: (PERSONAL NOTE) try to start gossip.
  -- 	   try to call a node from the first one (this might be with the bash script)
  -- 	   faire un rpc.call (faire une fct gossip qui selectionne un partenaire, qui lui fait un rpc et qui garde le statut)
	--     Rummor mongering: utiliser reservoir sampling
  
  
  -- this thread will be in charge of killing the node after max_time seconds
  events.periodic(5, gossip) -- voir doc, c'est pour appeler gossip toutes les tant de secondes.
  events.thread(terminator)
end  

events.thread(main)  
events.run()

