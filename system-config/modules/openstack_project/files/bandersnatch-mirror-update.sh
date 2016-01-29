#!/bin/bash

# Copyright 2016 IBM Corp.
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

echo "Obtaining bandersnatch tokens and running bandersnatch."
k5start -t -f /etc/bandersnatch.keytab service/bandersnatch -- timeout -k 2m 30m run-bandersnatch

RET=$?

if [ $RET -eq 0 ]; then
    echo "Bandersnatch completed successfully, running vos release."
    k5start -t -f /etc/afsadmin.keytab service/afsadmin -- vos release mirror.pypi
fi

echo "Done."
