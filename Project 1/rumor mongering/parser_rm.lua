--[[
	Description: parser implemented in Lua.
---------------------------------------------------------------------------------------------------
	Author: Laurent Hayez
	Date: 24 september 2015
--]]

function parser()
    io.input("logs/log_htl2_f5.txt")
    local nb_duplicates = 0
    local hashmap = {}
    
    for line in io.lines() do
       cur_line = line
       if string.match(line, "%d+:%d+:%d+.%d+%s%(%d+%)%s%s%d+:%d+:%d+%sduplicate_received") ~= nil then
	  nb_duplicates = nb_duplicates + 1
       end
	  
       if string.match(line, "%d+:%d+:%d+.%d+%s%(%d+%)%s%si_am_infected") ~= nil and #hashmap < 39 then
	  table.insert(hashmap, {nb_dupli = nb_duplicates, inf = string.match(line, "%d+:%d+:%d+.%d+%s%(%d+%)%s%si_am_infected")})
       end
    end

    file = io.open("parsed_logs_rm/log_htl2_f5_parsed.txt", "w+")
    for i,line  in ipairs(hashmap) do 
       file:write(hashmap[i].nb_dupli, "\t", i, "\n")
    end
    file:close()

end

-- Calling the function
parser()
