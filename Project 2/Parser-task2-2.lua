--
-- Author:      Laurent Hayez
-- Date:        06 oct. 2015
-- Last Modif:  06 nov. 2015
-- Description: Parser for the logs of task 2.2.
--

function parser()
    if #arg ~= 2 then
        print("Use syntax: lua " .. arg[0] .. " FILE_TO_PARSE DEST_OF_PARSED_FILE")
    else
        io.input(arg[1])
        local number_of_nodes = 64
        local number_of_hops = {}

        for line in io.lines() do
            -- inserting the number of hops in an array
            table.insert(number_of_hops, string.match(line, "%d+:%d+:%d+.%d+%s%(%d+%)%s%sNumber of hops:%s(%d)"))
        end

        -- sort the table we just created
        table.sort(number_of_hops)

        -- we will count how many nodes got the same number of hops
        local number_of_hops_per_key = {}
        -- initialization of the counters
        for i = 0, number_of_nodes do
            number_of_hops_per_key[i] = 0
        end

        -- counting how many keys have been found in number_of_hops[i]
        for i = 1, #number_of_hops do
            number_of_hops_per_key[tonumber(number_of_hops[i])] = number_of_hops_per_key[tonumber(number_of_hops[i])] + 1
        end

        local file = io.open(arg[2], "w+")
        for i = 0, number_of_nodes do
            file:write(i, "\t", number_of_hops_per_key[i], "\n")
        end
        file:close()
    end
end

-- Calling the function
parser()
