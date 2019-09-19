#!/usr/bin/bash

# Run this file to let git smudge your credentials so you don't have to 
# change them yourself.

# The changes this script makes will be made to `.git/config` and `.gitattributes`.

# -------------------------------------------------
# Change these before running the script
# -------------------------------------------------

your_developer_id="0123456789" # Your 10 digit developer ID. Example is FTT89576VQ
your_bundle_id="your.bundle.id" # Anything you want.

# -------------------------------------------------
# Don't change anything below
# -------------------------------------------------

project_developer_id_to_replace="FTT89576VQ" # Set to match the 10 digit developer ID of the project.
project_bundle_id_to_replace="ccrama.me" # Set to match the bundle ID of the project.

for i in "$@"; do
case $i in
    -h|--help)
    HELP=1
    ;;
    -i|--install)
    INSTALL=1
    ;;
    -u|--uninstall)
    UNINSTALL=1
    ;;
    -*|--*)
    HELP=1
    ;;
esac
done

usage="\
USAGE:
This script installs a smudge/clean filter for signing info in your Xcode 
projects. This is useful when a repo has signing credentials and you are 
not able to use them. The filters will handle automatically substituting 
your own credentials locally and reverting them back so Git doesn't \"see\" 
the changes.

FLAGS:
-i or --install:
    Install the filters to .git/config and .gitattributes
-u or --uninstall:
    Remove the filters from .git/config and .gitattributes
"

gitattributesAppendedLine="*.pbxproj filter=filter-credentials # Autoconfigured by setup-signing-filter.sh"
gitattributesAppendedLineEscaped="\*\.pbxproj filter=filter-credentials # Autoconfigured by setup-signing-filter\.sh"

# Display help option if no args or -h|--help or invalid flag
if [[ $# -eq 0 ]] || [[ $HELP -eq 1 ]]; then
	echo "$usage"
	exit
fi

if [[ $INSTALL -eq 1 ]]; then
    # Converts credentials from project's to yours when pulling
    git config filter.filter-credentials.smudge "sed -e 's/$project_developer_id_to_replace/$your_developer_id/' -e 's/$project_bundle_id_to_replace/$your_bundle_id/'"
    # Converts credentials from yours to project's when making commits
    git config filter.filter-credentials.clean "sed -e 's/$your_developer_id/$project_developer_id_to_replace/' -e 's/$your_bundle_id/$project_bundle_id_to_replace/'"
	
    # Add filter to .gitattributes if it isn't already there.
    if grep -q "$gitattributesAppendedLine" .gitattributes; then
    : # No-op
    else
        echo "$gitattributesAppendedLine" >> .gitattributes
    fi
    echo "Installed filters!"
    exit
fi

if [[ $UNINSTALL -eq 1 ]]; then
	git config --unset filter.filter-credentials.smudge
    git config --unset filter.filter-credentials.clean
    sed -i '' -e "/$gitattributesAppendedLineEscaped/d" .gitattributes
    echo "Uninstalled filters."
    exit
fi