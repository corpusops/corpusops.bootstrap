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
import traceback

W = os.path.abspath(os.path.relpath(os.path.dirname((__file__))))
if W not in sys.path:
    sys.path.append(W)

import helper_mod as _H  # noqa
OW = _H.OW
TOP = _H.TOP


def print_status(status, quiet=False):
    if not quiet:
        if status['error']:
            print('Errors:')
            k = 'error'
        if status['success']:
            print('Success:')
            k = 'success'
        print('  {0}'.format(json.dumps(status[k], indent=2)))


def parse_cli():
    parser = argparse.ArgumentParser(
        description='build images')
    parser.add_argument(
        '--quiet',
        default=False,
        action='store_true')
    parser.add_argument(
        '--log-level',
        default=os.environ.get('LOGLEVEL', 'info'),
        help='loglevel')
    default_images_files = (
        '{0}/docker/IMAGES.json'.format(OW))
    parser.add_argument(
        '--images-files',
        nargs='*',
        default=_H.splitstrip(
            os.environ.get(
                'IMAGES_FILE', default_images_files
            )),
        help='images json file')
    args = parser.parse_args()
    return args, vars(args)


def build_image(img, cwd=None, status=None):
    if status is None:
        status = {'error': {}, 'success': {}}
    if cwd is None:
        cwd = os.getcwd()
    working_dir = img.get('working_dir', None)
    image_file = img['file']
    if not working_dir:
        working_dir = cwd
    try:
        if working_dir != cwd:
            os.chdir(working_dir)
        try:
            ret = getattr(_H, '{0}_build'.format(img['builder_type']))(img)
            status['success'][image_file] = ret
        except (Exception,):
            trace = traceback.format_exc()
            status['error'][image_file] = trace
    finally:
        if os.getcwd() != cwd:
            os.chdir(cwd)
    return status


def build_images(images_files):
    status = {'error': {}, 'success': {}}
    cwd = os.getcwd()
    for images_file in images_files:
        imagesdata, errors = _H.parse_images_file(images_file)
        if errors:
            status['error']['parsing'] = errors
            break
        for imgid, img in enumerate(imagesdata['images']):
            _status = build_image(img, cwd=cwd)
            if _status['error']:
                status['error'][imgid] = _status
                break
            else:
                status['success'][imgid] = _status
        if status['error']:
            break
    return status


def main():
    args, vargs = parse_cli()
    _H.setup_logging(level=getattr(logging, vargs['log_level'].upper()))
    _H.log('build started')
    status = build_images(vargs['images_files'])
    rc = len(status['error']) > 0 and 1 or 0
    print_status(status, vargs['quiet'])
    return status, rc


if __name__ == '__main__':
    ret, rc = main()
    sys.exit(rc)
# vim:set et sts=4 ts=4 tw=80:
