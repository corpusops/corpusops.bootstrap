#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import os
import sys
import argparse
import json
import logging
import copy
import traceback

W = os.path.abspath(os.path.relpath(os.path.dirname((__file__))))
N = os.path.basename(__file__)
if W not in sys.path:
    sys.path.append(W)

import helper_mod as _H  # noqa
OW = _H.OW
TOP = _H.TOP
_STATUS = {'error': {}, 'success': {}, 'message': {}, 'skip': {}}
_HELP = '''\
Build images

Main usage:
  - {N} [--images packer__toto.json] [--skip-images packer_toto.json]
    - Iterate and run builds through packer or docker all the images found
      inside $docker_folder/IMAGES.json

Other usages:

  - {N} --generate-images \\
          [--packer-template $docker_folder/packer.json]
     - rewrite the packer template to $docker_folder/packer/IMG_X.json

  - {N} --list
    - List all available images

Details in REPO: /doc/docker_chain_build.md

'''.format(N=N)


def _print(data, level=0):
    if isinstance(data, (dict,)):
        for k, item in data.items():
            print('{1}{0}:'.format(k, ' '*level))
            _print(item, level+2)
        pass
    if isinstance(data, (tuple, list, set)):
        for item in data:
            _print(item, level+2)
    else:
        data = '{0}'.format(data).replace('\n', '\n{0}'.format(' '*level))
        print('{1}{0}'.format(data, ' '*level))


def print_status(status, quiet=False):
    if not quiet:
        for k in ['message', 'error', 'success', 'skip']:
            if status.get(k, None):
                print("\n"+k.capitalize()+'s:')
                for img in status[k]:
                    print(" "+img)
                    data = status[k][img]
                    _print(data, level=2)


def get_versions(versions_file):
    versions = None
    if not os.path.exists(versions_file):
        print('{0} isnt existing'.format(versions_file))
        sys.exit(1)
    with open(versions_file, 'r') as fic:
        versions = [a.strip() for a in fic.read().split() if a.strip()]
    return versions


def make_container(target):
    container = os.path.dirname(target)
    if not os.path.exists(container):
        os.makedirs(container)


def generate_images(images_files,
                    packer_template,
                    docker_folder='.docker',
                    salt_folder='.salt',
                    ansible_folder='.ansible',
                    status=None):
    if status is None:
        status = copy.deepcopy(_STATUS)
    with open(packer_template) as fic:
        content = fic.read()
    for images_file in images_files:
        imagesdata, errors = _H.parse_images_file(images_file)
        if not os.path.exists(packer_template):
            print('{0} isnt existing'.format(packer_template))
            sys.exit(1)
        for image in imagesdata['images']:
            v = image['version']
            n = image['name']
            res = content.replace('__VERSION__', v)
            res = res.replace('__NAME__', n)
            res = res.replace('__ANSIBLE_FOLDER', ansible_folder)
            res = res.replace('__SALT_FOLDER', salt_folder)
            res = res.replace('__DOCKER_FOLDER', docker_folder)
            target = '{0}/packer/{1}.json'.format(docker_folder, v)
            make_container(target)
            print('Writing {0}'.format(target))
            with open(target, 'w') as fic:
                fic.write(res)
    return status


def generate(versions_file, target):
    res = {'images': []}
    versions = get_versions(versions_file)
    for i in sorted(versions):
        j = i.strip()
        if j:
            res['images'].append(
              {"builder_type": "packer", "file": j+".json"}
            )
    make_container(target)
    print('Writing {0}'.format(target))
    with open(target, 'w') as fic:
        fic.write(json.dumps(res, indent=2))


def parse_cli():
    parser = argparse.ArgumentParser(usage=_HELP)
    parser.add_argument(
        '--generate-images',
        default=False,
        help=('Generate $docker_folder/packer/*'
              ' from $docker_folder/IMAGES.json'),
        action='store_true')
    parser.add_argument(
        '--quiet',
        default=False,
        action='store_true')
    parser.add_argument(
        '--dry-run',
        default=False,
        help='Run all build logic, but skip build step',
        action='store_true')
    parser.add_argument(
        '--list',
        default=False,
        help='list images instead of building',
        action='store_true')
    parser.add_argument(
        '--log-level',
        default=os.environ.get('LOGLEVEL', 'info'),
        help='loglevel')
    parser.add_argument(
        '--skip-images',
        nargs='*',
        default=_H.splitstrip(os.environ.get('SKIP_IMAGES', '')),
        help='do not build these images (all by default)')
    parser.add_argument(
        '--salt-folder',
        default=os.environ.get('SALT_FOLDER', 'salt'),
        help='salt folder (if used)')
    parser.add_argument(
        '--ansible-folder',
        default=os.environ.get('ANSIBLE_FOLDER', 'ansible'),
        help='ansible folder (if used)')
    parser.add_argument(
        '--docker-folder',
        default=os.environ.get('DOCKER_FOLDER', 'docker'),
        help='docker folder')
    parser.add_argument(
        '--images',
        nargs='*',
        default=_H.splitstrip(os.environ.get('BUILD_IMAGES', '')),
        help='build only these images (all by default)')
    parser.add_argument(
        '--packer-template',
        default=os.environ.get('PACKER_TEMPLATE', ''),
        help='packer template (default: $docker_folder/packer.json)')
    parser.add_argument(
        '--image-name',
        nargs='*',
        default='default image name',
        help='images json file (default: $docker_folder/IMAGES.json)')
    parser.add_argument(
        '--images-files',
        nargs='*',
        default=_H.splitstrip(os.environ.get('IMAGES_FILE', '')),
        help='images json file (default: $docker_folder/IMAGES.json)')
    args = parser.parse_args()
    for i in ['salt', 'ansible', 'docker']:
        opt = '{0}_folder'.format(i)
        folder = getattr(args, opt)
        folders = [folder]
        if not folder.startswith(('.', os.path.sep)):
            folders.append('.'+folder)
        for i in folders:
            if i and not i.startswith(os.path.sep):
                ffolder = os.path.join(OW, i)
                if os.path.exists(ffolder):
                    setattr(args, opt, i)
                    break
    if not args.packer_template:
        args.packer_template = os.path.join(args.docker_folder, 'packer.json')
    if not args.images_files:
        args.images_files = [os.path.join(args.docker_folder, 'IMAGES.json')]
    return args, vars(args)


def build_image(img, cwd=None, status=None, dry_run=False):
    if status is None:
        status = copy.deepcopy(_STATUS)
    if cwd is None:
        cwd = os.getcwd()
    builder_type = img['builder_type']
    working_dir = img.get('working_dir', None)
    image_file = img['file']
    k = "{0}__{1}".format(builder_type, image_file)
    if not working_dir:
        working_dir = cwd
    try:
        if working_dir != cwd:
            os.chdir(working_dir)
        try:
            if dry_run:
                ret = True
            else:
                ret = getattr(
                    _H, '{0}_build'.format(builder_type)
                )(img)
            if ret[0]:
                s = 'success'
            else:
                s = 'error'
            status[s][k] = ret
            _status = (True, s, status[s][k])
        except (Exception,):
            trace = traceback.format_exc()
            status['error'][k] = trace
            _status = (False, 'error', status['error'][k])
    finally:
        if os.getcwd() != cwd:
            os.chdir(cwd)
    return _status


def build_images(images_files, skip_images=None,
                 images=None, dry_run=False, status=None):
    if not images:
        images = []
    if not skip_images:
        skip_images = []
    if status is None:
        status = copy.deepcopy(_STATUS)
    cwd = os.getcwd()
    for images_file in images_files:
        imagesdata, errors = _H.parse_images_file(images_file)
        if errors:
            status['error']['parsing'] = errors
            break
        for img in imagesdata['images']:
            k = '{0}__{1}'.format(img['builder_type'], img['file'])
            skip = False
            if images and k not in images:
                skip = True
            if skip_images and k in skip_images:
                skip = True
            if skip:
                status['skip'][k] = True
                _status = (True, 'skip', True)
            else:
                _status = build_image(img, cwd=cwd,
                                      dry_run=dry_run, status=status)
            if not _status[0]:
                break
        if status['error']:
            break
    return status


def do_list(images_files, status=None):
    if status is None:
        status = copy.deepcopy(_STATUS)
    for images_file in images_files:
        imagesdata, errors = _H.parse_images_file(images_file)
        if errors:
            status['error']['parsing'] = errors
            break
        for img in imagesdata['images']:
            k = '{0}__{1}'.format(img['builder_type'], img['file'])
            status['message'][k] = '{0} --images={1}'.format(N, k)
    return status


def main():
    args, vargs = parse_cli()
    status = copy.deepcopy(_STATUS)
    _H.setup_logging(level=getattr(logging, vargs['log_level'].upper()))
    _H.log('build started')
    done = False

    if vargs['generate_images'] and not done:
        generate_images(images_files=vargs['images_files'],
                        docker_folder=vargs['docker_folder'],
                        ansible_folder=vargs['ansible_folder'],
                        salt_folder=vargs['salt_folder'],
                        packer_template=vargs['packer_template'])
        done = True

    if vargs['list'] and not done:
        status = do_list(vargs['images_files'], status=status)
        done = True

    if not done:
        status = build_images(vargs['images_files'], status=status,
                              images=vargs['images'],
                              skip_images=vargs['skip_images'],
                              dry_run=vargs['dry_run'])

    rc = len(status['error']) > 0 and 1 or 0
    print_status(status, vargs['quiet'])
    return status, rc


if __name__ == '__main__':
    ret, rc = main()
    sys.exit(rc)
# vim:set et sts=4 ts=4 tw=80:
