#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import os
import copy
import sys
import traceback
import json
import re
import logging
try:
    from queue import Queue
except ImportError:
    from Queue import Queue
from threading import Thread
import subprocess
from subprocess import PIPE, Popen
import pipes
from collections import OrderedDict

J = os.path.join
B = os.path.basename
D = os.path.dirname
A = os.path.abspath
R = os.path.relpath
OW = os.getcwd()
W = A(R(D(__file__)))
TOP = D(W)
RE_F = re.U | re.M
BUILDER_TYPES = ['packer', 'dockerfile']
DEFAULT_BUILDER_TYPE = 'packer'
NAME_SANITIZER = re.compile('setups\.',
                            flags=RE_F)
IMG_PARSER = re.compile('('
                        '(?P<repo>[^/]+)'
                        '/)?'
                        '(?P<image>[^:]+)'
                        '(:'
                        '(?P<tag>.*)'
                        ')?',
                        flags=RE_F)
_LOGGER = 'cops.dockerbuilder'
_LOGGER_FMT = '%(asctime)s:%(levelname)s:%(name)s:%(message)s'
_LOGGER_DFMT = '%m/%d/%Y %I:%M:%S %p'


def read_output(pipe, funcs):
    for line in iter(pipe.readline, ''):
        for func in funcs:
            func(line.decode('utf-8'))
    pipe.close()


def write_output(get):
    for line in iter(get, None):
        sys.stdout.write(line)


def run_cmd(command,
            shell=True,
            cwd=None,
            env=None,
            stdout=None,
            stderr=None,
            passthrough=True):
    if stderr is None:
        stderr = PIPE
    if stdout is None:
        stdout = PIPE
    if env is None:
        env = os.environ.copy()

    outs, errs = None, None
    proc = Popen(
        command,
        cwd=cwd,
        env=env,
        shell=shell,
        close_fds=True,
        stdout=stdout,
        stderr=stderr,
        bufsize=1)

    if passthrough:

        outs, errs = [], []

        q = Queue()

        stdout_thread = Thread(
            target=read_output, args=(proc.stdout, [q.put, outs.append]))
        stderr_thread = Thread(
            target=read_output, args=(proc.stderr, [q.put, errs.append]))
        writer_thread = Thread(target=write_output, args=(q.get,))
        for t in (stdout_thread, stderr_thread, writer_thread):
            t.daemon = True
            t.start()
        proc.wait()
        for t in (stdout_thread, stderr_thread):
            t.join()
        q.put(None)
        outs = ''.join(outs)
        errs = ''.join(errs)

    else:

        outs, errs = proc.communicate()
        outs = '' if outs is None else outs.decode('utf-8')
        errs = '' if errs is None else errs.decode('utf-8')

    rc = proc.returncode

    return (rc, (outs, errs))


def splitstrip(a, *s):
    return [b.strip() for b in a.split(*s)]


def shellexec(cmd, *args):
    msg = 'shellexec {0}'
    if args:
        msg += ' {1}'
    debug(msg.format(cmd, args))
    ret = run_cmd(cmd)
    return ret


def setup_logging(fmt=_LOGGER_FMT, datefmt=_LOGGER_DFMT, level=logging.INFO):
    logging.basicConfig(format=fmt, datefmt=datefmt, level=level)


def log(msg, name=_LOGGER, level='info'):
    logger = logging.getLogger(name)
    return getattr(logger, level.lower())(msg)


def debug(*a, **kwargs):
    kwargs['level'] = 'debug'
    return log(*a, **kwargs)


def parse_docker_images(images, images_file='images.json'):
    images_file = A(images_file)
    images_folder = D(images_file)
    parsed_images = []
    gerrors = []
    if 'images' not in images:
        gerrors.append(("No 'images' in images data'", images))
    else:
        for img in images.pop('images'):
            errors = []
            if not isinstance(img, dict):
                errors.append(('NOT_A_MAPPING', img))
            img['images_file'] = images_file
            try:
                builder_type = img['builder_type']
            except KeyError:
                builder_type = DEFAULT_BUILDER_TYPE
            try:
                if builder_type:
                    assert builder_type in BUILDER_TYPES
            except (ValueError, AssertionError,):
                builder_type = None
                errors.append(('INVALID_BUILDER_TYPE', img))
            #
            name = img.get('name', None)
            if not name:
                name = NAME_SANITIZER.sub('', os.path.basename(OW))
            img['name'] = name
            if not img['name']:
                errors.append(('NO_NAME', img))
            #
            version = img.get('version', None)
            image_file = img.get('file', None)
            if not image_file:
                if builder_type in ['packer']:
                    if version:
                        formatter = '{0}-{1}.json'
                    else:
                        formatter = '{0}.json'
                elif builder_type in ['dockerfile']:
                    if version:
                        formatter = 'Dockerfile.{0}-{1}'
                    else:
                        formatter = 'Dockerfile'
                else:
                    raise Exception(
                        'no valid builder type for {0}'.format(img))
                image_file = formatter.format(name, version)
            img['file'] = image_file
            if (
                builder_type and image_file and not
                image_file.startswith(os.path.sep)
            ):
                img['fimage_file'] = J(
                    images_folder, builder_type, image_file)
            if not image_file:
                errors.append(('NO_IMAGE_FILE_ERROR', img))
            #
            if not version:
                version = '.'.join(img['file'].split('.')[:-1]).strip()
            img['version'] = version
            if not img['version']:
                errors.append(('NO_VERSION', img))
            #
            if builder_type in ['dockerfile']:
                tag = None
                try:
                    tag = img['tag']
                except KeyError:
                    errors.append(('NO_TAG', img))
                img_info, img_parts = IMG_PARSER.search(tag), None
                if tag and not img_info:
                    errors.append(('INVALID_DOCKER_TAG', img))
                else:
                    img_parts = img_info.groupdict()
                img['img_parts'] = img_parts
            try:
                working_dir = img['working_dir']
            except KeyError:
                working_dir = J(images_folder, '..')
            img['working_dir'] = A(working_dir)
            if not os.path.isdir(img['working_dir']):
                errors.append(
                    ('working dir {0} is not a dir'.format(img['working_dir']),
                     img))
            if not errors:
                parsed_images.append(img)
            else:
                gerrors.extend(errors)
        images['images'] = parsed_images
    return images, gerrors


def parse_images_file(images_file):
    images, errors = {}, []
    fimages_file = A(images_file)
    debug('parse_images_file: {0}'.format(fimages_file))
    if not os.path.exists(fimages_file):
        errors.append(('Images file {0} does not exists', fimages_file))
    with open(fimages_file) as fic:
        try:
            images = json.loads(fic.read())
        except (Exception,):
            print(traceback.format_exc())
            errors.append(('IMAGES_FILE_NOT_A_JSON', fimages_file))
        else:
            images, errors = parse_docker_images(images, fimages_file)
    return images, errors


def _build(cmd, img, fmt=True, builder_args=None, *a, **kw):
    img = copy.deepcopy(img)
    img.setdefault('extra_args', '')
    iargs = copy.deepcopy(img)
    iargs.update(img)
    iargs['builder_args'] = builder_args or ''
    if fmt:
        cmd = cmd.format(**iargs)
    img_file = iargs['fimage_file']
    try:
        os.stat(img_file)
    except (OSError, IOError):
        msg = ('retcode: {0}\n'
               'OUT: {1}\n'
               'ERR: {2}\n'.format(
                   -1,
                   '',
                   'IMAGEFILE_DOES_NOT_EXIST: {0}'.format(
                       img_file)))
    else:
        ret = shellexec(cmd)
        if ret[0] == 0:
            status = True
        else:
            status = False
        msg = ('retcode: {0}\n'
               'OUT: {1}\n'
               'ERR: {2}\n'.format(ret[0],
                                   ret[1][0],
                                   ret[1][1]))
    return status, msg


def packer_build(img, *a, **kw):
    cmd = ('cd \'{working_dir}\' &&'
           ' packer build {builder_args} {extra_args} {fimage_file}')
    return _build(cmd, img, *a, **kw)


def dockerfile_build(img, *a, **kw):
    cmd = ('docker build {builder_args} {extra_args}'
           ' -f {fimage_file} -t {tag} {working_dir}')
    return _build(cmd, img, *a, **kw)
# vim:set et sts=4 ts=4 tw=80:
