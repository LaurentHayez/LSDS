"""
**
** Author:      Laurent Hayez
** Date:        15 dec 2015
** File:        Python parser to check for the cycle lengths and window emission length
**              (Part of Firefly project)
**
"""
import getopt
import re

import sys


class Parser(object):
    def __init__(self, input_file):
        self.input_file = input_file

    def get_number_of_nodes(self):
        return int(re.match('Logs/Firefly-\w\w-(\d+).+', self.input_file).group(1))

    @staticmethod
    def get_time(line):
        """
        Function get_time
        :param line: line of the log containing a timestamp of the form HH:MM:SS.NNNN
        :return: Time in seconds
        """
        time = re.match('(\d+):(\d+):(\d+)\.(\d+) \(\d+\)  \w+', line)
        return int(time.group(1)) * 3600 + int(time.group(2)) * 60 + int(time.group(3)) + int(time.group(4)) / 10 ** (
            len(time.group(4)))

    def get_initial_time_and_id(self):
        """
        Function get_initial_time: reads input_file until it finds the first flash
        :rtype: object
        :return: time (in seconds) of the first flash
        """
        with open(self.input_file, 'r') as f:
            for line in f:
                current_line = re.match('(\d+):(\d+):(\d+)\.\d+ \(\d+\)  Node (\d+) emitted a flash.', line)
                if current_line:
                    return self.get_time(line), int(current_line.group(4))

    # Need to define the thing to create all the tables and stuff
    def get_timestamps(self):
        """
        get_timestamps: reads the input_file (log) and every time a node emits a flash, the time at which the flash was
                        emitted is stored in the i-th array of lists_time (where i is the id of the node).
        :return: the lists containing the time at which nodes emitted light.
        """
        init_time, _ = self.get_initial_time_and_id()
        lists_time = [[] for i in range(self.get_number_of_nodes())]
        with open(self.input_file, 'r') as ifile:
            for line in ifile:
                current_line = re.match('(\d+):(\d+):(\d+)\.(\d)\d* \(\d+\)  Node (\d+) emitted a flash.', line)
                if current_line:
                    lists_time[int(current_line.group(5)) - 1].append(self.get_time(line) - init_time)
        return lists_time


def get_paths():
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'hi:', ['ifile='])
    except getopt.GetoptError:
        print('python3 Parser-synchronization.py -i <input file>')
        sys.exit(2)

    for opt, arg in opts:
        if opt == '-h':
            print('python3 Parser-synchronization.py -i <input file>')
            print('Ex: \"python3 Parser-synchronization.py -i foo\" will get the file Logs/foo.txt')
            sys.exit()
        elif opt in ('-i', '--ifile'):
            input_file = 'Logs/' + str(arg) + '.txt'
            output_file_cl = 'Parsed-logs/' + str(arg) + '-cl-parsed.txt'
            output_file_ewl = 'Parsed-logs/' + str(arg) + '-ewl-parsed.txt'

    return input_file, output_file_cl, output_file_ewl


def cycle_lengths(lists, ofile):
    with open(ofile, 'w') as output_file:
        for elem in lists:
            for i in range(1, len(elem)):
                output_file.write(str(elem[i]) + '\t' + str(elem[i] - elem[i - 1]) + '\n')


def get_closests(lists, time):
    # This is not the best thing to do, but radius = Delta/2
    # I did not want to create another parameter, especially that I only used Delta = 5 in my test.
    radius = 2.5
    closests = []
    for l in lists:
        i = 0
        while i < len(l)-1 and abs(l[i] - time) > radius:
            i += 1
        # Now we found an element in the ball of center time and radius 2.5.
        # We need to check which of this element or the successor is closest to time.
        if abs(l[i] - time) <= radius:
            if i < len(l) - 2 and abs(l[i] - time) > abs(l[i + 1] - time):
                closests.append(l[i + 1])
            else:
                closests.append(l[i])
    return closests


def emission_window_length(lists, ofile, ref_id):
    """
    Explanation of how the function works:
      1. We get the id of the node that emitted the first flash. This will be our ref_id (passed in parameter)
      2. Every time this node emit a flash, we look for all the nodes that emitted a flash less than 2.5 seconds
         before or after the node. We consider that it is in the same emission.

      node id      node 3 = ref node, At first node 2 is not in the emission window.
         ^      -----------
         |   3  |    o     |        o              o
         |      |<-- 5 --->|
         |   2  |          |       o               o
         |      |<2.5>     |
         |   1  |     o    |         o             o
         |      -----------
         --------------------------------------------------------> time

      3. Once we have this list, we look for the min and max, and max-min is our emission window length for the
         current emission.
      4. Do this for every time ref_id flashed.
    WARNING: As the nodes do not start at the same time, we do NOT consider the flashes after ref_id node stops.
    :param lists: list containing the times at which every node flashed
    :param ofile: output file
    :param ref_id: reference id of the node that first flashed
    """
    with open(ofile, 'w') as output_file:
        for time in lists[ref_id]:
            lists_closests = get_closests(lists, time)
            # to get min and max of list, we use the built in functions in python
            min_time = min(lists_closests)
            max_time = max(lists_closests)
            length = max_time - min_time
            output_file.write('{0}\t{1}\n'.format(str(time), str(length)))


def main():
    ifile, ofile_cl, ofile_ewl = get_paths()

    parser = Parser(ifile)

    _, init_id = parser.get_initial_time_and_id()

    lists_time = parser.get_timestamps()

    cycle_lengths(lists_time, ofile_cl)

    emission_window_length(lists_time, ofile_ewl, init_id)


if __name__ == '__main__':
    main()
