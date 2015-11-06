--[[
	Description: parser implemented in Lua.
---------------------------------------------------------------------------------------------------
	Author: Laurent Hayez
	Date: 24 september 2015
1--]]

function parser()
    io.input("log.txt")
    local number_of_nodes, i = 40, 1
    local hours = {}
    local useful_lines = {}
    local minutes = {}
    local seconds = {}
    local CPUloads={}
    --local set_for_id = {}
    
    for line in io.lines() do
        -- Getting the timestamp
       -- print(string.match(line,  "%d+:%d+:%d+.%d+%s%(%d+%)%s%si_am_infected"))
       table.insert(useful_lines, string.match(line, "%d+:%d+:%d+.%d+%s%(%d+%)%s%si_am_infected"))
    end
    for i,v in ipairs(useful_lines) do
       print(useful_lines[i])
    end

    file = io.open("parsed_text_file.txt", "a+")
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
       file:write(elapsed_time, "\t", i, "\t", (i/number_of_nodes), "\n")
    end
    file:close()

end

-- Calling the function
parser()
