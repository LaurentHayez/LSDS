"""
**
** Author:      Laurent Hayez
** Date:        03 dec 2015
** File:        Python parser to check for the synchronization
**              (Part of Firefly project)
**
"""

import getopt
import sys
import re


def get_time(line):
    time = re.match('(\d+):(\d+):(\d+)\.(\d)\d* \(\d+\)  \w+', line)
    return int(time.group(1)) * 3600 + int(time.group(2)) * 60 + int(time.group(3)) + int(time.group(4)) / 10


def init_parser():
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


def parser():
    input_file, output_file = init_parser()
    init_time = 0
    with open(input_file, 'r') as f:
        for line in f:
            current_line = re.match('(\d+):(\d+):(\d+)\.\d+ \(\d+\)  Node (\d+) emitted a flash.', line)
            if current_line:
                init_time = get_time(line)
                break
    input_file = open(input_file, 'r')
    output_file = open(output_file, 'w')

    for line in input_file:
        current_line = re.match('(\d+):(\d+):(\d+)\.(\d)\d* \(\d+\)  Node (\d+) emitted a flash.', line)
        if current_line:
            current_time = get_time(line)
            output_file.write(str(current_time - init_time) + "\t" + current_line.group(5) + "\n")


def main():
    parser()


if __name__ == '__main__':
    main()
