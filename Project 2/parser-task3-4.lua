--[[
	Description: parser implemented in Lua.
---------------------------------------------------------------------------------------------------
	Author: Laurent Hayez
	Date: 24 september 2015
1--]]

function parser()
    log = "keys-churn.txt"
    input_file = io.open("Logs/"..log, "r")
    local number_of_nodes, i, keys_found_counter, total_keys, intervals, keys_not_found = 64, 1, 0, 0, 0, 0
    local hours = 0
    local useful_lines = {}
    local minutes = 0
    local seconds = 0
    local time_between_checks = 10

    first_line = input_file:read()
    initial_time = string.match(first_line, "(%d+):%d+:%d+.%d+")*3600 + string.match(first_line, "%d+:(%d+):%d+.%d+")*60 + string.match(first_line, "%d+:%d+:(%d+).%d+")
    file = io.open("ParsedLogs/"..log, "w+")
    --file:write("0", "\t", "0", "\t", "0", "\n")

    -- Get last line of log
    local len = input_file:seek("end", -31) -- last line is 16:48:14.599655 (117)  END_LOG => 31 caracters
    local txt = input_file:read("*a")
    local end_time = (string.match(txt, "(%d+):%d+:%d+.%d+")*3600 + string.match(txt, "%d+:(%d+):%d+.%d+")*60 + string.match(txt, "%d+:%d+:(%d+).%d+"))
    local total_elapsed_time = end_time - initial_time

    --[[
    for line in io.lines("Logs/"..log) do
       table.insert(useful_lines, string.match(line, "%d+:%d+:%d+.%d+%s%(%d+%)%s%sStale reference to finger%[%d+%]"))
    end
    --]]
    
    for line in io.lines("Logs/"..log) do
       hours = string.match(line, "(%d+):%d+:%d+.%d+")
       minutes = string.match(line, "%d+:(%d+):%d+.%d+")
       seconds = string.match(line, "%d+:%d+:(%d+).%d+")
       -- multiply everything by 3600 or 60 to be in seconds.
       time = hours*3600 + minutes*60 + seconds
       elapsed_time = time - initial_time
       if elapsed_time <= time_between_checks and string.match(line, "%d+:%d+:%d+.%d+%s%(%d+%)%s%sKey to find:%s%d+") then
	  total_keys = total_keys + 1
       elseif elapsed_time <= time_between_checks and string.match(line, "%d+:%d+:%d+.%d+%s%(%d+%)%s%sKey%s%d+%sfound") then
	  keys_found_counter = keys_found_counter + 1
       elseif elapsed_time <= time_between_checks and string.match(line, "%d+:%d+:%d+.%d+%s%(%d+%)%s%sFailed to find the key%s%d+") then
	  keys_not_found = keys_not_found + 1
       elseif elapsed_time > time_between_checks then
	  current_time = elapsed_time + time_between_checks*intervals
	  -- format: elapsed_time (per 20 seconds)   number of stale references for the past 20 seconds   average number of stale references 
	  file:write(current_time, "\t", keys_found_counter, "\t", (keys_found_counter/total_keys), "\n")
	  initial_time = time
	  intervals = intervals + 1
	  --keys_found_counter = 0
       end
    end
    file:close()
    input_file:close()

end

-- Calling the function
parser()
