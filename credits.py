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

VERSION = '0.5.0'
PROG = os.path.basename(os.path.splitext(__file__)[0])
DESCRIPTION = """Generate a `Settings.bundle` friendly plist file from all
 'LICENSE.*' files in a given directory. Inspired by JosephH and Sean's
 comments on stackoverflow: http://stackoverflow.com/q/6428353"""


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


def main(_):
    def list_callback(option, _, value, option_parser):
        setattr(option_parser.values, option.dest, [item.strip() for item in value.split(',')])

    parser = OptionParser(option_class=MultipleOption,
                          usage='usage: %prog -s source_path -o output_plist -e [exclude_paths]',
                          version='%s %s' % (PROG, VERSION),
                          description=DESCRIPTION)
    parser.add_option('-s', '--source',
                      action="callback", type="string",
                      dest='input_path',
                      metavar='source_path',
                      help='comma separated list of directories to recursively search for licenses',
                      callback=list_callback)
    parser.add_option('-o', '--output-plist',
                      type="string",
                      dest='output_file',
                      metavar='output_plist',
                      help='path to the plist to be generated')
    parser.add_option('-e', '--exclude',
                      action="callback", type="string",
                      dest='excludes',
                      metavar='path1, ...',
                      help='comma separated list of paths to be excluded',
                      callback=list_callback)
    parser.add_option('-t', '--test',
                      action="store_true",
                      dest='include_tests',
                      metavar='include_tests',
                      default=False,
                      help='include files in the `Tests` directory for unit testing')
    if len(sys.argv) == 1:
        parser.parse_args(['--help'])

    options, args = parser.parse_args()

    print options.input_path
    for path in options.input_path:
        if(not os.path.isdir(path)):
            print "Error: Source path does not exist: %s" % path
            sys.exit(2)

    if not options.output_file.endswith('.plist'):
        print("Error: Outputfile must end in .plist")
        sys.exit(2)

    plist = plist_from_dirs(
        options.input_path,
        options.excludes,
        options.include_tests
    )
    plistlib.writePlist(plist, options.output_file)
    return 0


def plist_from_dirs(directories, excludes, include_tests):
    """
    Recursively searches each directory in 'directories' and generate plists objects 
    from any LICENSE files found.
    """
    plist = {'PreferenceSpecifiers': [], 'StringsTable': 'Acknowledgements'}
    for directory in directories:
        license_paths = license_paths_from_dir(directory)
        plist_paths = (plist_path for plist_path in license_paths if not exclude_path(plist_path, excludes, include_tests))
        for plist_path in plist_paths:
            license_dict = plist_from_file(plist_path)
            plist['PreferenceSpecifiers'].append(license_dict)

    plist['PreferenceSpecifiers'] = sorted(plist['PreferenceSpecifiers'], key=lambda x: x['Title'])
    return plist


def license_paths_from_dir(directory):
    return_dict = []
    os.chdir(sys.path[0])
    for dir_path, _, file_names in os.walk(directory):
        file_names = (file_name for file_name in file_names if file_name.startswith("LICENSE"))
        for file_name in file_names:
            return_dict.append(os.path.join(dir_path, file_name))
    return return_dict


def plist_from_file(path):
    """
    Returns a plist representation of the file at 'path'. Uses the name of the
    parent folder for the title property.
    """
    base_group = {'Type': 'PSGroupSpecifier', 'FooterText': '', 'Title': ''}
    current_file = open(path, 'r')
    group = deepcopy(base_group)
    title = path.split("/")[-2]
    group['Title'] = unicode(title, 'utf-8')
    src_body = current_file.read()
    body = ""
    for match in re.finditer(r'(?s)((?:[^\n][\n]?)+)', src_body):
        body = body + re.sub("(\\n)", " ", match.group()) + "\n\n"
    body = unicode(body, 'utf-8')
    group['FooterText'] = rchop(body, " \n\n")
    return group


def exclude_path(path, excludes, is_testing):
    if "/LicenseGenerator-iOS/Example/" in path:
        return True
    elif "/LicenseGenerator-iOS/Tests/" in path:
        return not is_testing
    elif excludes is None:
        return False

    for pattern in excludes:
        if re.search(pattern.strip(), path, re.S) is not None:
            return True
    return False


def rchop(str, ending):
    if str.endswith(ending):
        return str[:-len(ending)]
    return str


if __name__ == "__main__":
    main(sys.argv[1:])
