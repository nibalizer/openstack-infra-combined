#!/bin/bash
# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

export ELEMENTS_PATH=${ELEMENTS_PATH:-nodepool/elements}
export DISTRO=${DISTRO:-ubuntu}
export IMAGE_NAME=${IMAGE_NAME:-devstack-gate}
export NODEPOOL_SCRIPTDIR=${NODEPOOL_SCRIPTDIR:-nodepool/scripts}
export CONFIG_SOURCE=${CONFIG_SOURCE:-https://git.openstack.org/openstack-infra/system-config}
export CONFIG_REF=${CONFIG_REF:-master}

disk-image-create -x --no-tmpfs -o $IMAGE_NAME $DISTRO \
    vm openstack-repos puppet nodepool-base node-devstack
