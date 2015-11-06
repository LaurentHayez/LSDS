--[[
	Description: parser implemented in Lua.
---------------------------------------------------------------------------------------------------
	Author: Laurent Hayez
	Date: 24 september 2015
1--]]

function parser()
   if #arg < 1 or #arg > 1 then
      print("Use syntax: lua "..arg[0].." FILE_TO_PARSE")
   else
      io.input(arg[1])
      local number_of_nodes, i = 40, 1
      local hours, useful_lines, minutes, seconds = {}, {}, {}, {}
      
      for line in io.lines() do
	 -- inserting the lines we are interested in in an array
	 table.insert(useful_lines, string.match(line, "%d+:%d+:%d+.%d+%s%(%d+%)%s%si_am_infected"))
      end
      
      file = io.open("parsed_"..arg[1], "w+")
      for i,line  in ipairs(useful_lines) do 
	 hours[i] = string.match(line, "(%d+):%d+:%d+.%d+")
	 minutes[i] = string.match(line, "%d+:(%d+):%d+.%d+")
	 seconds[i] = string.match(line, "%d+:%d+:(%d+).%d+")
	 if i == 1 then
	    initial_time = hours[1]*3600 + minutes[1]*60 + seconds[1]
	 end
	 -- multiply hours by 3600 and minutes by 60 to have only seconds
	 time_i = hours[i]*3600 + minutes[i]*60 + seconds[i]
	 elapsed_time = time_i - initial_time
	 file:write(elapsed_time, "\t", i, "\t", (i/number_of_nodes), "\n")
      end
      file:close()
   end
   
end

-- Calling the function
parser()
