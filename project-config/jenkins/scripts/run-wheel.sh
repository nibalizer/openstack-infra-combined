#!/bin/bash -xe

# Copyright 2013 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

venv=${1:-venv}

export UPPER_CONSTRAINTS_FILE=$(pwd)/upper-constraints.txt

rm -f dist/*.whl
tox -e$venv pip install wheel
tox -e$venv python setup.py bdist_wheel

FILES=dist/*.whl
for f in $FILES; do
    echo -n "SHA1sum for $f: "
    sha1sum $f | awk '{print $1}' | tee $f.sha1

    echo -n "MD5sum for $f: "
    md5sum $f  | awk '{print $1}' | tee $f.md5
done
