--[[
	Description: parser implemented in Lua.
---------------------------------------------------------------------------------------------------
	Author: Laurent Hayez
	Date: 24 september 2015
1--]]

function parser()
    io.input("Logs/stale_refs_log.txt")
    local number_of_nodes, i, stale_refs_counter, intervals = 64, 1, 0, 0
    local hours = {}
    local useful_lines = {}
    local minutes = {}
    local seconds = {}
    local CPUloads={}
    
    for line in io.lines() do
        -- Getting the timestamp
       -- print(string.match(line,  "%d+:%d+:%d+.%d+%s%(%d+%)%s%si_am_infected"))
       table.insert(useful_lines, string.match(line, "%d+:%d+:%d+.%d+%s%(%d+%)%s%sStale reference to finger%[%d+%]"))
    end
    --[[
    for i,v in ipairs(useful_lines) do
       print(useful_lines[i])
    end
    --]]

    file = io.open("ParsedLogs/parsed_stale_refs.txt", "w+")
    for i,line  in ipairs(useful_lines) do 
       hours[i] = string.match(line, "(%d+):%d+:%d+.%d+")
       minutes[i] = string.match(line, "%d+:(%d+):%d+.%d+")
       seconds[i] = string.match(line, "%d+:%d+:(%d+).%d+")
       if i == 1 then
	  initial_time = hours[1]*3600 + minutes[1]*60 + seconds[1]
       end
       -- tout multiplier par 60 pour être en secondes!
       time_i = hours[i]*3600 + minutes[i]*60 + seconds[i]
       elapsed_time = time_i - initial_time
       if elapsed_time <= 20 then
	  stale_refs_counter = stale_refs_counter + 1
       else
	  current_time = elapsed_time + 20*intervals
	  -- format: elapsed_time (per 20 seconds)   number of stale references for the past 20 seconds   average number of stale references 
	  file:write(current_time, "\t", stale_refs_counter, "\t", (stale_refs_counter/#useful_lines), "\n")
	  initial_time = time_i
	  intervals = intervals + 1
	  stale_refs_counter = 0
       end
    end
    file:close()

end

-- Calling the function
parser()
