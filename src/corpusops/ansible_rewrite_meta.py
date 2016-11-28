#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import os
import sys
import argparse
import ruamel.yaml
from corpusops.utils import dictupdate
import copy


D = os.path.dirname
A = os.path.abspath
T = D(A(__name__))


DEFAULTS = '''
galaxy_info:
  author: Mathieu Le Marec - Pasquet <kiorky@cryptelium.net>
  description: |
    {role}
  company: corpusOps
  issue_tracker_url: |
    https://github.com/corpusops/{role}/issues/new
  namespace: {namespace}
  license: BSD
  min_ansible_version: 2.0
  github_branch: master
  platforms:
  - name: GenericLinux
    versions:
    - all
    - any
  - name: Ubuntu
    versions:
    - all
  - name: Debian
    versions:
    - all
  galaxy_tags: [corpusops, corpusops_roles]
dependencies: []
'''


def yload(code):
    data = ruamel.yaml.load(code, ruamel.yaml.RoundTripLoader)
    return data

def ydump(data):
    return ruamel.yaml.round_trip_dump(data)


def rewrite_meta(rolepath, namespace='corpusops'):
    rolename = os.path.basename(rolepath)
    m = os.path.join(rolepath, 'meta/main.yml')
    defaults = DEFAULTS.format(
        namespace=namespace,
        role=rolename)
    data = yload(defaults)
    existing = {}
    if os.path.exists(m):
        with open(m) as fic:
            existing = yload(fic.read())
    else:
        m = {}
    if existing:
        data = dictupdate(data, copy.deepcopy(existing))
    datad = ydump(data).strip()
    existingd = ydump(existing).strip()
    if datad != existingd:
        with open(m, 'w') as fic:
            fic.write(datad)
    return data, existing


def find_metas(paths):
    roles = []
    if paths:
        for p in paths:
            ap = A(p)
            if not os.path.isdir(ap):
                continue
            for dirpath, dirs, files in os.walk(ap):
                adp = A(dirpath)
                cdirs = dirs[:]
                # not recurse into roles themselves
                if adp.count('/') != ap.count('/'):
                    for i in range(len(dirs)):
                        dirs.pop()
                is_role = False
                for i in 'tasks', 'defaults', 'vars', 'meta':
                    if i in cdirs:
                        is_role = True
                        break
                if is_role:
                    roles.append(adp)
    return roles



def main():
    os.chdir(T)
    parser = argparse.ArgumentParser(
        description='Process some integers.')
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('-p', '--paths', action='append')
    parser.add_argument('-r', '--release',
                        action='store_true', default=False,
                        help='galaxy release')
    args = parser.parse_args()
    roles = find_metas(args.paths)
    for role in roles:
        rewrite_meta(role)



if __name__ == '__main__':
    main()
# vim:set et sts=4 ts=4 tw=80:
