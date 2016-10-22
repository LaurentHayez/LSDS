"""
**
** Author:      Laurent Hayez
** Date:        03 dec 2015
** File:        Python parser to check for the emission window size
**              (Part of Firefly project)
**
"""

import getopt
import sys
import re


def get_time(line):
    time = re.match('(\d+):(\d+):(\d+)\.(\d+) \(\d+\)  \w+', line)
    return int(time.group(1)) * 3600 + int(time.group(2)) * 60 + int(time.group(3)) + int(time.group(4)) / 10 ** (
        len(time.group(4)))


def init_parser():
    input_file = ''
    output_file = ''

    try:
        opts, args = getopt.getopt(sys.argv[1:], 'hi:o:', ['ifile=', 'ofile='])
    except getopt.GetoptError:
        print('python3 Parser-emission-window.py -i <input file> -o <output file>')
        sys.exit(2)

    for opt, arg in opts:
        if opt == '-h':
            print('python3 Parser-emission-window.py -i <input file> -o <output file>')
            sys.exit()
        elif opt in ('-i', '--ifile'):
            input_file = arg
        elif opt in ('-o', '--ofile'):
            output_file = arg

    return input_file, output_file


def parser():
    input_file, output_file = init_parser()
    reference_time, initial_time, current_time, delta = 0, 0, 0, 5
    is_reference_time, is_initial_time = False, False
    input_file = open(input_file, 'r')
    output_file = open(output_file, 'w')

    for line in input_file:
        current_line = re.match('(\d+):(\d+):(\d+)\.(\d)\d* \(\d+\)  Node (\d+) emitted a flash.', line)

        if current_line and not is_initial_time:
            initial_time = get_time(line)
            is_initial_time = True

        if current_line and not is_reference_time:
            reference_time = get_time(line)
            is_reference_time = True

        if current_line and get_time(line) - reference_time < delta:
            current_time = get_time(line)
        elif current_line and get_time(line) - reference_time >= delta:
            output_file.write(str(current_time - initial_time) + "\t" + str(current_time - reference_time) + "\n")
            reference_time = get_time(line)

    input_file.close()
    output_file.close()


def main():
    parser()


if __name__ == '__main__':
    main()
