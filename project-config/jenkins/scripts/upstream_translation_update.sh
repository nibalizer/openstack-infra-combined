#!/bin/bash -xe

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

PROJECT=$1

# Replace /'s in branch names with -'s because Zanata doesn't
# allow /'s in version names.
ZANATA_VERSION=${ZUUL_REFNAME//\//-}

source /usr/local/jenkins/slave_scripts/common_translation_update.sh

if ! /usr/local/jenkins/slave_scripts/query-zanata-project-version.py \
    -p $PROJECT -v $ZANATA_VERSION; then
    # Exit successfully so that lack of a version doesn't cause the jenkins
    # jobs to fail. This is necessary because not all branches of a project
    # will be translated.
    exit 0
fi

setup_git

# Project setup and updating POT files.
case "$PROJECT" in
    api-site|ha-guide|openstack-manuals|operations-guide|security-doc)
        init_manuals "$PROJECT"
        # POT file extraction is done in setup_manuals.
        setup_manuals "$PROJECT" "$ZANATA_VERSION"
        ;;
    training-guides)
        setup_training_guides "$ZANATA_VERSION"
        ;;
    django_openstack_auth)
        # NOTE: Once POT file and Zanata resource name are renamed
        # from openstack_auth(.pot) to django(.pot), the below can be used.
        # setup_django django_openstack_auth openstack_auth "$ZANATA_VERSION"
        setup_django_openstack_auth "$ZANATA_VERSION"
        # NOTE: Once django_openstack_auth repo has babel-django.cfg,
        # the below can be used.
        # extract_messages_django openstack_auth
        extract_messages openstack_auth
        ;;
    horizon)
        setup_horizon "$ZANATA_VERSION"
        ./run_tests.sh --makemessages -V
        ;;
    # Test of translation setup improvement
    murano-dashboard|magnum-ui)
        # TODO(amotoki): Honor module name in extract_*
        # MODULENAME=$(get_modulename $PROJECT python)
        # if [ -n "$MODULENAME" ]; then
        #     setup_project "$PROJECT" "$ZANATA_VERSION"
        #     setup_loglevel_vars
        #     extract_messages
        #     extract_messages_log "$PROJECT"
        # fi
        MODULENAME=$(get_modulename $PROJECT django)
        if [ -n "$MODULENAME" ]; then
            setup_django "$PROJECT" "$MODULENAME" "$ZANATA_VERSION"
            extract_messages_django "$MODULENAME"
        fi
        ;;
    python-*)
        echo "project temporarily disabled"
        exit 0
        ;;
    oslo.*)
        echo "project temporarily disabled"
        exit 0
        ;;
    ironic-inspector|networking-*|neutron-*|vmware-nsx)
        echo "project temporarily disabled"
        exit 0
        ;;
    *)
        setup_project "$PROJECT" "$ZANATA_VERSION"
        setup_loglevel_vars
        extract_messages "$PROJECT"
        extract_messages_log "$PROJECT"
        ;;
esac

# Add all changed files to git.
# Note that setup_manuals did the git add already, so we can skip it
# here.
if [[ ! $PROJECT =~ api-site|ha-guide|openstack-manuals|operations-guide|security-doc ]]; then
    git add */locale/*
fi

if [ $(git diff --cached | egrep -v "(POT-Creation-Date|^[\+\-]#|^\+{3}|^\-{3})" | egrep -c "^[\-\+]") -gt 0 ]; then
    # The Zanata client works out what to send based on the zanata.xml file.
    # Do not copy translations from other files for this change.
    zanata-cli -B -e push --copy-trans False
fi
