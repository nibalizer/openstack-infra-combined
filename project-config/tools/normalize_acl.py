#!/usr/bin/env python

# Usage: normalize_acl.py acl.config [transformation [transformation [...]]]
#
# Transformations:
# all Apply all transformations.
# 0 - dry run (default, print to stdout rather than modifying file in place)
# 1 - strip/condense whitespace and sort (implied by any other transformation)
# 2 - get rid of unneeded create on refs/tags
# 3 - remove any project.stat{e,us} = active since it's a default or a typo
# 4 - strip default *.owner = group Administrators permissions
# 5 - sort the exclusiveGroupPermissions group lists
# 6 - replace openstack-ci-admins and openstack-ci-core with infra-core
# 7 - add at least one core team, if no team is defined with special suffixes
#     like core, admins, milestone or Users

import re
import sys

aclfile = sys.argv[1]

try:
    transformations = sys.argv[2:]
    if transformations and transformations[0] == 'all':
        transformations = [str(x) for x in range(0, 8)]
except KeyError:
    transformations = []


def tokens(data):
    """Human-order comparison

    This handles embedded positive and negative integers, for sorting
    strings in a more human-friendly order."""
    data = data.replace('.', ' ').split()
    for n in range(len(data)):
        try:
            data[n] = int(data[n])
        except ValueError:
            pass
    return data


acl = {}
out = ''

if '0' in transformations or not transformations:
    dry_run = True
else:
    dry_run = False

aclfd = open(aclfile)
for line in aclfd:
    # condense whitespace to single spaces and get rid of leading/trailing
    line = re.sub('\s+', ' ', line).strip()
    # skip empty lines
    if not line:
        continue
    # this is a section heading
    if line.startswith('['):
        section = line.strip(' []')
        # use a list for this because some options can have the same "key"
        acl[section] = []
    # key=value lines
    elif '=' in line:
        acl[section].append(line)
    # WTF
    else:
        raise Exception('Unrecognized line: "%s"' % line)
aclfd.close()

if '2' in transformations:
    for key in acl:
        if key.startswith('access "refs/tags/'):
            acl[key] = [
                x for x in acl[key]
                if not x.startswith('create = ')]

if '3' in transformations:
    try:
        acl['project'] = [x for x in acl['project'] if x not in
                          ('state = active', 'status = active')]
    except KeyError:
        pass

if '4' in transformations:
    for section in acl.keys():
        acl[section] = [x for x in acl[section] if x !=
                        'owner = group Administrators']

if '5' in transformations:
    for section in acl.keys():
        newsection = []
        for option in acl[section]:
            key, value = [x.strip() for x in option.split('=')]
            if key == 'exclusiveGroupPermissions':
                newsection.append('%s = %s' % (
                    key, ' '.join(sorted(value.split()))))
            else:
                newsection.append(option)
        acl[section] = newsection

if '6' in transformations:
    for section in acl.keys():
        newsection = []
        for option in acl[section]:
            for group in ('openstack-ci-admins', 'openstack-ci-core'):
                option = option.replace('group %s' % group, 'group infra-core')
            newsection.append(option)
        acl[section] = newsection

if '7' in transformations:
    special_projects = (
        'ossa',
        'reviewday',
    )
    special_teams = (
        'admins',
        'Bootstrappers',
        'committee',
        'core',
        'maint',
        'Managers',
        'milestone',
        'packagers',
        'release',
        'Users',
    )
    for section in acl.keys():
        newsection = []
        for option in acl[section]:
            if ('refs/heads' in section and 'group' in option
                    and '-2..+2' in option
                    and not any(x in option for x in special_teams)
                    and not any(x in aclfile for x in special_projects)):
                option = '%s%s' % (option, '-core')
            newsection.append(option)
        acl[section] = newsection

for section in sorted(acl.keys()):
    if acl[section]:
        out += '\n[%s]\n' % section
        for option in sorted(acl[section], key=tokens):
            out += '%s\n' % option

if dry_run:
    print(out[1:-1])
else:
    aclfd = open(aclfile, 'w')
    aclfd.write(out[1:])
    aclfd.close()
