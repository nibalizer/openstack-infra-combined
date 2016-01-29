#!/usr/bin/python
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
#
# Extract Python package name from setup.cfg

import ConfigParser

universal = False

setup_cfg = ConfigParser.SafeConfigParser()
setup_cfg.read("setup.cfg")
if setup_cfg.has_option("bdist_wheel", "universal"):
    universal = setup_cfg.getboolean("bdist_wheel", "universal")
elif setup_cfg.has_option("wheel", "universal"):
    universal = setup_cfg.getboolean("wheel", "universal")

if universal:
    print("py2.py3")
else:
    print("py2")
