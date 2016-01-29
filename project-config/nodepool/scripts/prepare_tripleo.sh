#!/bin/bash -xe

# Copyright (C) 2011-2013 OpenStack Foundation
# Copyright (C) 2013 Hewlett-Packard Development Company, L.P.
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
#
# See the License for the specific language governing permissions and
# limitations under the License.

# Enable precise-backports so we can install jq
if [ -f /usr/bin/apt-get ]; then
    sudo sed -i -e 's/# \(deb .*precise-backports main \)/\1/g' \
        /etc/apt/sources.list
    sudo apt-get update
fi

cd /opt/nodepool-scripts/
./install_devstack_dependencies.sh

# toci scripts use both of these
sudo -H pip install gear os-apply-config

# tripleo-gate runs with two networks - the public access network and eth1
# pointing at the in-datacentre L2 network where we can talk to the test
# environments directly. We need to enable DHCP on eth1 though.
# Note that we don't bring it up during prepare - it's only needed to run
# tests.

if [ -d /etc/sysconfig/network-scripts ]; then
    sudo dd of=/etc/sysconfig/network-scripts/ifcfg-eth1 << EOF
DEVICE="eth1"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
PEERDNS="no"
EOF

elif [ -f /etc/network/interfaces ]; then
    sudo dd of=/etc/network/interfaces oflag=append conv=notrunc << EOF
auto eth1
iface eth1 inet dhcp
EOF

# Workaround bug 1270646 for actual slaves
    sudo dd of=/etc/network/interfaces.d/eth0.cfg oflag=append conv=notrunc << EOF
    post-up ip link set mtu 1458 dev eth0
EOF

else
    echo "Unsupported distro."
    exit 1
fi
