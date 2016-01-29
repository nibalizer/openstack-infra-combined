#!/bin/bash -xe

# It checks that projects.yaml alphabetized and prints list of projects that
# should be sorted.

export TMPDIR=`/bin/mktemp -d`
trap "rm -rf $TMPDIR" EXIT

pushd $TMPDIR
PROJECTS_LIST=$OLDPWD/$1

sed -e '/^- project: /!d' -e 's/^- project: //' $PROJECTS_LIST > projects_list

LC_ALL=C sort --ignore-case projects_list -o projects_list.sorted

if ! diff projects_list projects_list.sorted > projects_list.diff; then
    echo "The following projects should be alphabetized: "
    cat projects_list.diff | grep -e '> '
    exit 1
else
    echo "Projects alphabetized."
fi

popd
