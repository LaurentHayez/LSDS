"""
**
** Author:      Laurent Hayez
** Date:        15 dec 2015
** File:        Python parser to check for the cycle lengths and window emission length
**              (Part of Firefly project)
**
"""

import re

class Parser(object):

    def __init__(self, input_file, output_file):
        self.input_file = input_file
        self.output_file = output_file

    def get_number_of_nodes():
        return int(re.match('Logs/Firefly-\w\w-(\d+).+', self.input_file).group(1))

    # Need to define the thing to create all the tables and stuff
        
        

def get_paths():
    input_file = ''
    output_file = ''

    try:
        opts, args = getopt.getopt(sys.argv[1:], 'hi:o:', ['ifile=', 'ofile='])
    except getopt.GetoptError:
        print('Parser-synchronization -i <input file> -o <output file>')
        sys.exit(2)

    for opt, arg in opts:
        if opt == '-h':
            print('Parser-synchronization -i <input file> -o <output file>')
            sys.exit()
        elif opt in ('-i', '--ifile'):
            input_file = arg
        elif opt in ('-o', '--ofile'):
            output_file = arg

    return input_file, output_file
    
