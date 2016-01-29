:title: Nodepool

.. _nodepool:

Nodepool
########

Nodepool is a service used by the OpenStack CI team to deploy and manage a pool
of devstack images on a cloud server for use in OpenStack project testing.

At a Glance
===========

:Hosts:
  * nodepool.openstack.org
:Puppet:
  * https://git.openstack.org/cgit/openstack-infra/puppet-openstackci/tree/manifests/nodepool.pp
  * :file:`modules/openstack_project/manifests/single_use_slave.pp`
:Configuration:
  * :config:`nodepool/nodepool.yaml`
  * :config:`nodepool/scripts/`
  * :config:`nodepool/elements/`
:Projects:
  * https://git.openstack.org/cgit/openstack-infra/nodepool
:Bugs:
  * https://storyboard.openstack.org/#!/project/668
:Resources:
  * `Nodepool Reference Manual <http://docs.openstack.org/infra/nodepool>`_

Overview
========

Once per day, for every image type (and provider) configured by nodepool, a new
image with cached data for use by devstack.  Nodepool spins up new instances
and tears down old as tests are queued up and completed, always maintaining a
consistent number of available instances for tests up to the set limits of the
CI infrastructure.

Bad Images
==========

Since nodepool takes a while to build images, and generally only does
it once per day, occasionally the images it produces may have
significant behavior changes from the previous versions.  For
instance, a provider's base image or operating system package may
update, or some of the scripts or system configuration that we apply
to the images may change.  If this occurs, it is easy to revert to the
last good image.

Nodepool periodically deletes old images, however, it never deletes
the current or next most recent image in the ``ready`` state for any
image-provider combination.  So if you find that the
``devstack-precise`` images for a single or all providers are
problematic, you can run::

  $ sudo nodepool image-list

  +--------+--------------------+------------------------+----------------------------------------------------------+------------+--------------------------------------+--------------------------------------+----------+-------------+
  | ID     | Provider           | Image                  | Hostname                                                 | Version    | Image ID                             | Server ID                            | State    | Age (hours) |
  +--------+--------------------+------------------------+----------------------------------------------------------+------------+--------------------------------------+--------------------------------------+----------+-------------+
  | 168655 | hpcloud-az2        | devstack-precise       | devstack-precise-1394417686.template.openstack.org       | 1394417686 | 387612                               | 4909797                              | ready    | 26.83       |
  | 168696 | hpcloud-az2        | devstack-precise       | devstack-precise-1394514268.template.openstack.org       | 1394514268 | 388782                               | 4930213                              | ready    | 0.75        |
  +--------+--------------------+------------------------+----------------------------------------------------------+------------+--------------------------------------+--------------------------------------+----------+-------------+

Image 168655 is the previous image and 168696 is the current image
(they are both marked as ``ready`` and the current image is simply the
image with the shortest age.  Delete the problematic image with::

  $ sudo nodepool image-delete 168696

Then the previous image, 168655, will become the current image and
nodepool will use it when creating new nodes.  When nodepool next
creates an image, it will still retain 168655 since it will still be
considered the next-most-recent image.

vhd-util
========

Creating images for Rackspace requires a patched version of vhd-util to convert
the images into the appropriate VHD format. A package is manaually managed
at `ppa:openstack-ci-core/vhd-util` and is based on a git repo at
https://github.com/emonty/vhd-util

Updating vhd-util
-----------------

Should it become required to update vhd-util before Infra has a proper
packaging repo or solution in place, one should clone from the git repo::

  $ git clone git://github.com/emonty/vhd-util
  $ cd vhd-util

Then perform whatever updates and packaging work are needed. The repo is
formatted as a git-buildpackage repo with `--pristine-tar`. When you're ready
to upload a new verion, commit, create a source package and a tag::

  $ git-buildpackage --git-tag --git-sign-tags -S

This will make a source package in the parent directory. Upload it to
launchpad::

  $ cd ..
  $ dput ppa:openstack-ci-core/vhd-util vhd-util_$version_source.changes

Then probably pushing the repo to github and submitting a pull request so that
we can keep up with the change is not a terrible idea.
