#!/usr/bin/sh

# Run this file to let git smudge your credentials so you don't have to 
# reenter them when pulling master or changing branches.

# The changes this script makes will be made to `.git/config` in the root of the repo.
# If you want to reset the changes, run `git config --unset-all filter.filter-credentials`
# in the root of the repo.

# -------------------------------------------------
# Change these before running the script
# -------------------------------------------------

your_developer_id="1234567890" # Your 10 digit developer ID. Example is FTT89576VQ
your_usr_id="anything.you.want" # Anything you want. Sets USR_DOMAIN in the project.

# -------------------------------------------------
# Don't change anything below
# -------------------------------------------------

# These should change if the values are changed in the project.
project_developer_id="FTT89576VQ"
project_usr_id="ccrama.me"

# Converts credentials from project's to yours when pulling
git config filter.filter-credentials.smudge "sed -e 's/$project_developer_id/$your_developer_id/' -e 's/$project_usr_id/$your_usr_id/'"
# Converts credentials from yours to project's when making commits
git config filter.filter-credentials.clean "sed -e 's/$your_developer_id/$project_developer_id/' -e 's/$your_usr_id/$project_usr_id/'"