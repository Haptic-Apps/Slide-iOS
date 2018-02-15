#!/usr/bin/python
# coding: utf-8

"""
    Recursively searches the input directory for 'LICENSE.*' files and compiles
    them into a Settings.bundle friendly plist. Inspired by JosephH
    and Sean's comments on stackoverflow: http://stackoverflow.com/q/6428353

    :usage: ./credits.py -s project/ -o project/Settings.bundle/Credits.plist

    :author: Carlo Eugster (http://carlo.io)
    :license: MIT, see LICENSE for more details.
"""

import os
import sys
import plistlib
import re
import codecs
from optparse import OptionParser
from optparse import Option, OptionValueError
from copy import deepcopy

VERSION = '0.3'
PROG = os.path.basename(os.path.splitext(__file__)[0])
DESCRIPTION = '''Recursively searches the input directory for 'LICENSE.*' files and compiles them into a Settings.bundle friendly plist. Inspired by JosephH and Sean's comments on stackoverflow: http://stackoverflow.com/q/6428353'''

class MultipleOption(Option):
    ACTIONS = Option.ACTIONS + ("extend",)
    STORE_ACTIONS = Option.STORE_ACTIONS + ("extend",)
    TYPED_ACTIONS = Option.TYPED_ACTIONS + ("extend",)
    ALWAYS_TYPED_ACTIONS = Option.ALWAYS_TYPED_ACTIONS + ("extend",)

    def take_action(self, action, dest, opt, value, values, parser):
        if action == "extend":
            values.ensure_value(dest, []).append(value)
        else:
            Option.take_action(self, action, dest, opt, value, values, parser)


def main(argv):
    def exclude_callback(option, opt, value, parser):
        setattr(parser.values, option.dest, value.split(','))

    parser = OptionParser(option_class=MultipleOption,
                              usage='usage: %prog -s source_path -o output_plist -e [exclude_paths]',
                              version='%s %s' % (PROG, VERSION),
                              description=DESCRIPTION)
    parser.add_option('-s', '--source', 
                   type="string",
                  dest='inputpath', 
                  metavar='source_path', 
                  help='source directory to search for licenses')
    parser.add_option('-o', '--output-plist', 
                   type="string",
                  dest='outputfile', 
                  metavar='output_plist', 
                  help='path to the plist to be generated')
    parser.add_option('-e', '--exclude', 
                  action="callback", type="string",
                  dest='excludes', 
                  metavar='path1, ...', 
                  help='comma separated list of paths to be excluded',
                  callback=exclude_callback)
    if len(sys.argv) == 1:
        parser.parse_args(['--help'])

    OPTIONS, args = parser.parse_args()

    if(not os.path.isdir(OPTIONS.inputpath)):
        print "Error: Invalid source path: %s" % OPTIONS.inputpath
        sys.exit(2)

    if(not OPTIONS.outputfile.endswith('.plist')):
        print "Error: Outputfile must end in .plist"
        sys.exit(2)

    plist = plistFromDir(OPTIONS.inputpath, OPTIONS.excludes)
    plistlib.writePlist(plist,OPTIONS.outputfile)
    return 0

def plistFromDir(dir, excludes):
    """
    Recursilvely search 'dir' to generates plist objects from LICENSE files.
    """
    plist = {'PreferenceSpecifiers': [], 'StringsTable': 'Acknowledgements'}
    os.chdir(sys.path[0])
    for root, dirs, files in os.walk(dir):
        for file in files:
            if file.startswith("LICENSE"):
                plistPath = os.path.join(root, file)
                if not excludePath(plistPath, excludes):
                    license = plistFromFile(plistPath)
                    plist['PreferenceSpecifiers'].append(license)
    return plist

def plistFromFile(path):
    """
    Returns a plist representation of the file at 'path'. Uses the name of the
    paremt folder for the title property.
    """
    base_group = {'Type': 'PSGroupSpecifier', 'FooterText': '', 'Title': ''}
    current_file = open(path, 'r')
    group = deepcopy(base_group)
    title = path.split("/")[-2]
    group['Title'] = unicode(title, 'utf-8')
    srcBody = current_file.read()
    body = ""
    for match in re.finditer(r'(?s)((?:[^\n][\n]?)+)', srcBody):
        body = body + re.sub("(\\n)", " ", match.group()) + "\n\n"
    body = unicode(body, 'utf-8')
    group['FooterText'] = rchop(body, " \n\n")
    return group
    
def excludePath(path, excludes):
    if excludes is None:
        return False
    for pattern in excludes:
        if(re.search(pattern.strip(), path, re.S) != None):
            return True
    return False
    
def rchop(str, ending):
    if str.endswith(ending):
        return str[:-len(ending)]
    return str

if __name__ == "__main__":
    main(sys.argv[1:])
