#!/usr/bin/env python3
import argparse
import json
import logging
import textwrap
from collections import namedtuple

logger = logging.getLogger('suggest_hardware')


def setup_logging():
    """
    Set basic configuration for the logging system.
    """
    logging.basicConfig(level=logging.INFO, format='[%(name)s] %(levelname)s: %(message)s')


def parse_command_line_arguments():
    """
    Parse command line arguments.
    """
    description = textwrap.dedent("""\
    This Python script reads the Abaqus dat-file created by a datacheck run and extracts the 
    "memory estimates to minimize I/O". It then suggests a coretype and a corecount based on 
    the maximum memory required.
    """)

    parser = argparse.ArgumentParser(
        description=description,
        epilog="Please report bugs to rbitsche@rescale.com",
    )

    parser.add_argument("dat_file", help="The Abaqus dat-file from a datacheck run.")

    return parser.parse_args()


def find_max_memory_estimate(dat_file_path):
    """
    Find the highest memory estimate (memory to minimize I/O) in the Abaqus dat file.
    :param str dat_file_path: path to the Abaqus dat-file
    :return: the highest memory estimate
    :rtype: float
    """
    with open(dat_file_path, 'r') as file:
        lines = file.readlines()
    memory_lines = [
        lines[i+6].strip() for i, line in enumerate(lines) if 'M E M O R Y   E S T I M A T E' in line
    ]

    memory_estimates = []
    for line in memory_lines:
        estimates = [float(item) for item in line.split()]
        memory_estimates.append(estimates[3])

    return max(memory_estimates)


def get_hardware(memory_required):

    choices = [
        {'code': 'kyanite', 'corecount': corecount, 'memory': corecount * 8000}
        for corecount in [1, 2, 4, 8, 16, 24, 32, 48, 64]
    ]
    for coretype in choices:
        if coretype['memory'] > memory_required:
            return coretype
    return None


def main():

    setup_logging()
    cl_args = parse_command_line_arguments()
    max_memory = find_max_memory_estimate(cl_args.dat_file)
    logger.info(f'Maximum memory estimate to minimise I/O in file {cl_args.dat_file} is {max_memory} MB.')
    coretype = get_hardware(max_memory)
    logger.info(f'Suggested coretype: {coretype}')

    if coretype is None:
        coretype = {'code': 'kyanite', 'corecount': 64, 'memory': 512000}
        logger.warning(f'No coretype suggestion found. Using default: {coretype}')

    outfilename = 'hardware.json'
    with open('hardware.json', "w") as f:
        json.dump(coretype, f, indent=4)
    logger.info(f'Coretype information written to {outfilename}.')


if __name__ == '__main__':
    main()



