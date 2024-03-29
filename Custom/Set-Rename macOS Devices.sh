﻿#!/usr/bin/python
'''
Rename computer from remote CSV using Jamf binary

Pass in the URL to your remote CSV file using script parameter 4

The remote CSV could live on a web server you control, OR be a Google Sheet
specified in the following format:

https://docs.google.com/spreadsheets/u/0/d/<document ID>/export?format=csv&id=<document ID>&gid=0
'''


import os
import sys
import urllib2
import subprocess


CSV_PATH = '/var/tmp/computernames.csv'


def download_csv(url):
    '''Downloads a remote CSV file to CSV_PATH'''
    try:
        # open the url
        csv = urllib2.urlopen(url)
        # ensure the local path exists
        directory = os.path.dirname(CSV_PATH)
        if not os.path.exists(directory):
            os.makedirs(directory)
        # write the csv data to the local file
        with open(CSV_PATH, 'w+') as local_file:
            local_file.write(csv.read())
        # return path to local csv file to pass along
        return CSV_PATH
    except (urllib2.HTTPError, urllib2.URLError):
        print 'ERROR: Unable to open URL', url
        return False
    except (IOError, OSError):
        print 'ERROR: Unable to write file at', CSV_PATH
        return False


def rename_computer(path):
    '''Renames a computer using the Jamf binary and local CSV at <path>'''
    cmd = ['/usr/local/bin/jamf', 'setComputerName', '-fromFile', path]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, _ = proc.communicate()
    if proc.returncode == 0:
        # on success the jamf binary reports 'Set Computer Name to XXX'
        # so we split the phrase and return the last element
        return out.split(' ')[-1]
    else:
        return False


def main():
    '''Main'''
    try:
        csv_url = sys.argv[4]
    except ValueError:
        print 'ERROR: You must provide the URL of a remote CSV file.'
        sys.exit(1)
    computernames = download_csv(csv_url)
    if computernames:
        rename = rename_computer(computernames)
        if rename:
            print 'SUCCESS: Set computer name to', rename
        else:
            print ('ERROR: Unable to set computer name. Is this device in the '
                   'remote CSV file?')
            sys.exit(1)
    else:
        print 'ERROR: Unable to set computer name without local CSV file.'
        sys.exit(1)


if __name__ == '__main__':
    main()