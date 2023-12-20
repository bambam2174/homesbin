#!/bin/bash

# use bash strict mode
set -euo pipefail

# delete the venv, if it already exists
rm -rf pyvenv

# create the venv
python3 -m venv pyvenv

# activate it
source pyvenv/bin/activate

# upgrade pip inside the venv and add support for the wheel package format
pip install -U pip wheel

# Change the following section depending on what your tool needs!

# install some concrete packages
# pip install requests
# pip install pyyaml

# or, install all packages from src/requirements.txt
# pip install -r src/requirements.txt
