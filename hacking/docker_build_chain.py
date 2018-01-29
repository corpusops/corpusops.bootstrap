#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import argparse
import copy
import json
import logging
import os
import re
import six
import sys
import time
import traceback
from threading import Thread
from subprocess import PIPE, Popen
from collections import OrderedDict


try:
    from queue import Queue
except ImportError:
    from Queue import Queue


J = os.path.join
B = os.path.basename
D = os.path.dirname
A = os.path.abspath
R = os.path.relpath
OW = os.getcwd()
W = A(R(D(__file__)))
TOP = D(W)
RE_F = re.U | re.M
N = os.path.basename(__file__)
BN = os.path.basename(N)
if sys.argv and sys.argv[0].endswith(os.path.sep+BN):
    N = sys.argv[0]

_STATUS = OrderedDict([('error', OrderedDict()), ('success', OrderedDict()),
                       ('message', OrderedDict()), ('skip', OrderedDict())])
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

BUILDER_TYPES = ['packer', 'dockerfile']
DEFAULT_BUILDER_TYPE = 'packer'
NAME_SANITIZER = re.compile('setups\.',
                            flags=RE_F)
PACKER_RETRY_CHECK = re.compile(
    ("/tmp/script[^.]+.sh: not found.*"
     "Build 'docker' errored: "
     "Script exited with non-zero exit status: 127"),
    flags=re.M | re.U | re.S)
IMG_PARSER = re.compile('('
                        '(?P<registry>'
                        '(?P<registry_host>[^:]+)'
                        ':'
                        '(?P<registry_port>[^/]+)'
                        ')'
                        '/)?'
                        '('
                        '(?P<repo>[^/:]+)'
                        '/)?'
                        '(?P<image>[^/:]+)'
                        '(:'
                        '(?P<tag>.*)'
                        ')?'
                        '$',
                        flags=RE_F)
_LOGGER = 'cops.dockerbuilder'
_LOGGER_FMT = '%(asctime)s:%(levelname)s:%(name)s:%(message)s'
_LOGGER_DFMT = '%m/%d/%Y %I:%M:%S %p'


def test_image_matcher():
    assert IMG_PARSER.match('b/a:1').groupdict() == {
        'image': 'a', 'repo': 'b', 'registry_host': None,
        'tag': '1', 'registry': None, 'registry_port': None}
    assert IMG_PARSER.match('b').groupdict() == {
        'image': 'b', 'repo': None, 'registry_host': None,
        'tag': None, 'registry': None, 'registry_port': None}
    assert IMG_PARSER.match('b:1').groupdict() == {
        'image': 'b', 'repo': None, 'registry_host': None,
        'tag': '1', 'registry': None, 'registry_port': None}
    assert IMG_PARSER.match('b/a').groupdict() == {
        'image': 'a', 'repo': 'b', 'registry_host': None,
        'tag': None, 'registry': None, 'registry_port': None}
    IMG_PARSER.match('c:2/b/a:1').groupdict() == {
        'image': 'a', 'repo': 'b', 'registry_host': 'c',
        'tag': '1', 'registry': 'c:1', 'registry_port': '2'}
    for i in [
        ':b'
        '/a'
        '/b/a'
        '/b/a:1'
        'c/b/a:1'
    ]:
        try:
            IMG_PARSER.match(i).groupdict()
            raise ValueError(i)
        except AttributeError:
            pass


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


def shellexec(cmd, quiet=False, *args):
    msg = 'shellexec {0}'
    if args:
        msg += ' {1}'
    debug(msg.format(cmd, args))
    ret = run_cmd(cmd, passthrough=not quiet)
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
            dockerfile = img.get(
                'dockerfile',
                img.get('docker_file', None))
            try:
                if dockerfile:
                    builder_type = 'docker'
                else:
                    builder_type = img['builder_type']
            except KeyError:
                builder_type = DEFAULT_BUILDER_TYPE

            builder_type = {'docker': 'dockerfile'}.get(
                builder_type, builder_type)
            img['builder_type'] = builder_type
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
            image_file = img.get(
                'file', dockerfile)
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
                image_file = formatter.format(name, version,
                                              name=name, version=version)
            img['file'] = image_file
            if (
                builder_type in ['packer'] and
                image_file and not
                image_file.startswith(os.path.sep)
            ):
                img['fimage_file'] = J(
                    images_folder, builder_type, image_file)
            if not image_file:
                errors.append(('NO_IMAGE_FILE_ERROR', img))
            #
            if builder_type in ['dockerfile']:
                tag = None
                try:
                    tag = img['tag']
                except KeyError:
                    errors.append(('NO_TAG', img))
                img_info, img_parts = IMG_PARSER.match(tag), None
                if tag and not img_info:
                    errors.append(('INVALID_DOCKER_TAG', img))
                else:
                    img_parts = img_info.groupdict()
                img['img_parts'] = img_parts
                new_name = img_parts.get('image', None)
                new_tag = img_parts.get('tag', None)
                if new_tag:
                    img['version'] = version = new_tag
                if new_name:
                    img['name'] = name = new_name
                if '{' in image_file and '}' in image_file:
                    image_file = image_file.format(name, version, **img)
            img['file'] = image_file
            if not version:
                version = '.'.join(img['file'].split('.')[:-1]).strip()
            img['version'] = version
            if not img['version']:
                errors.append(('NO_VERSION', img))
            try:
                working_dir = img['working_dir']
            except KeyError:
                working_dir = J(images_folder, '..')
            img['working_dir'] = A(working_dir)
            if (
                builder_type in ['dockerfile'] and
                image_file and not
                image_file.startswith(os.path.sep)
            ):
                img['fimage_file'] = J(
                    img['working_dir'], image_file)
            if not os.path.isdir(img['working_dir']):
                errors.append(
                    ('working dir {0} is not a dir'.format(img['working_dir']),
                     img))
            extra_args = img.setdefault('extra_args', '')
            if '{' in extra_args and '}' in extra_args:
                img['extra_args'] = extra_args.format(**img)
            if not errors:
                parsed_images.append(img)
            else:
                gerrors.extend(errors)
        images['images'] = parsed_images
    return images, gerrors


def parse_images_file(images_file):
    images, errors = OrderedDict(), []
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


class CharsetError(Exception):
    '''.'''
    val = None


def try_charsets(val, charsets=None):
    if charsets is None:
        charsets = ['utf-8', 'utf-16',
                    'iso-8859-15  ', 'iso-8859-1',
                    'cp1252', 'cp1253', 'cp1254', 'cp1255', 'cp1256']
    charsets = charsets[:]
    try:
        if not isinstance(val, unicode):
            return val
        else:
            while True:
                charset = charsets.pop(0)
                try:
                    return val.encode(charset)
                except UnicodeEncodeError:
                    pass
    except IndexError:
        pass
    exc = CharsetError(u'Cannot make msg from output (charset problem)')
    exc.val = val
    raise(exc)


def _build(cmd,
           img,
           fmt=True,
           builder_args=None,
           build_retries=None,
           build_retry_check=None,
           build_retry_delay=None,
           quiet=False,
           *a, **kw):
    if build_retry_delay is None:
        build_retry_delay = 1
    if build_retry_check is None:
        if img['builder_type'] == 'packer':
            build_retry_check = PACKER_RETRY_CHECK
    if build_retries is None:
        if img['builder_type'] == 'packer':
            build_retries = 10
        else:
            build_retries = 1
    img = copy.deepcopy(img)
    iargs = copy.deepcopy(img)
    iargs.update(img)
    iargs.setdefault('builder_args', builder_args or '')
    if fmt:
        cmd = cmd.format(**iargs)
    img_file = iargs['fimage_file']
    try:
        os.stat(img_file)
    except (OSError, IOError):
        status = False
        msg = ('retcode: {0}\n'
               'OUT: {1}\n'
               'ERR: {2}\n'.format(
                   -1,
                   '',
                   'IMAGEFILE_DOES_NOT_EXIST: {0}'.format(
                       img_file)))
    else:
        for i in range(build_retries):
            if i > 0:
                log(msg)
                log('Retry: {0}'.format(i))
            ret = shellexec(cmd, quiet=quiet)
            if ret[0] == 0:
                status = True
            else:
                status = False
            parts = [('retcode:', "{0}".format(ret[0])),
                     ('OUT:', ret[1][0]),
                     ('ERR:', ret[1][1])]
            msg = ''
            for label, val in parts:
                try:
                    msg += '{0} '.format(label)
                    msg += try_charsets(val)
                    msg += '\n'
                except (CharsetError,) as exc:
                    print(
                        u'ERROR {0}: Cannot make msg from output '
                        '(charset problem)'.format(label))
                    try:
                        print(exc.val)
                    except Exception:
                        # dont interrupt a whole build just for a failed print
                        pass
            if status:
                break
            else:
                if build_retry_check:
                    out_match = build_retry_check.search(ret[1][0])
                    err_match = build_retry_check.search(ret[1][1])
                    if (out_match or err_match):
                        time.sleep(build_retry_delay)
                    else:
                        break
                else:
                    break
    return status, msg


def packer_build(img, *a, **kw):
    kw.setdefault('build_retries', 10)
    cmd = ('cd \'{working_dir}\' &&'
           ' packer build {builder_args} {extra_args} {fimage_file}')
    return _build(cmd, img, *a, **kw)


def dockerfile_build(img, *a, **kw):
    cmd = ('docker build {builder_args} {extra_args}'
           ' -f {fimage_file} -t {tag} {working_dir}')
    return _build(cmd, img, *a, **kw)


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
    for k in ['message', 'success']:
        if status.get(k, None):
            print("\n"+k.capitalize()+'s:')
            for img in status[k]:
                data = status[k][img]
                if quiet:
                    if k == 'success':
                        data = (True, '')
                print(" "+img)
                _print(data, level=2)
    for k in ['message', 'error', 'skip']:
        if status.get(k, None):
            print("\n"+k.capitalize()+'s:')
            for img in status[k]:
                data = status[k][img]
                print(" "+img)
                _print(data, level=2)


def image_index(img):
    if img['builder_type'] == 'dockerfile':
        k = '{0}__{1}'.format(img['builder_type'], img['tag'])
    else:
        k = '{0}__{1}'.format(img['builder_type'], img['file'])
    return k


def index_images(imagesdata):
    ret = OrderedDict()
    for img in imagesdata['images']:
        ret[image_index(img)] = img
    return ret


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
        imagesdata, errors = parse_images_file(images_file)
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
            target = image['fimage_file']
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
    quiet_mode = bool(os.environ.get('TRAVIS', '').strip())
    no_squash = bool(os.environ.get('NO_SQUASH', '').strip())
    parser.add_argument(
        '--generate-images',
        default=False,
        help=('Generate $docker_folder/packer/*'
              ' from $docker_folder/IMAGES.json'),
        action='store_true')
    parser.add_argument(
        '--quiet',
        default=quiet_mode,
        action='store_true')
    parser.add_argument(
        '--no-squash',
        default=no_squash,
        help='if docker mode: do not squash resulting image',
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
        default=splitstrip(os.environ.get('SKIP_IMAGES', '')),
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
        default=splitstrip(os.environ.get(
            'IMAGES',
            os.environ.get('BUILD_IMAGES', ''))),
        help='build only these images (all by default)')
    parser.add_argument(
        '--packer-template',
        default=os.environ.get('PACKER_TEMPLATE', ''),
        help='packer template (default: $docker_folder/packer.json)')
    parser.add_argument(
        '--builder-args',
        default=os.environ.get('BUILDER_ARGS', ''),
        help='docker build/packer build CLI args')
    parser.add_argument(
        '--image-name',
        nargs='*',
        default='default image name',
        help='images json file (default: $docker_folder/IMAGES.json)')
    parser.add_argument(
        '--images-files',
        nargs='*',
        default=splitstrip(os.environ.get('IMAGES_FILE', '')),
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


def build_image(img,
                cwd=None,
                status=None,
                dry_run=False,
                builder_args=None,
                quiet=False):
    if status is None:
        status = copy.deepcopy(_STATUS)
    if cwd is None:
        cwd = os.getcwd()
    builder_type = img['builder_type']
    working_dir = img.get('working_dir', None)
    k = image_index(img)
    if not working_dir:
        working_dir = cwd

    try:
        if working_dir != cwd:
            os.chdir(working_dir)
        log_pre = ('{img[builder_type]}:'
                   '({working_dir}):{img[file]} -> {img[tag]}').format(
                       working_dir=working_dir, img=img)
        try:
            if dry_run:
                ret = True
            else:
                log(log_pre+' build started')
                ret = globals()[
                    '{0}_build'.format(builder_type)
                ](img, builder_args=builder_args, quiet=quiet)
            if ret[0]:
                s = 'success'
            else:
                s = 'error'
            status[s][k] = ret
            log(log_pre+' build success')
            _status = (True, s, status[s][k])
        except (Exception,):
            log(log_pre+' build failed')
            trace = traceback.format_exc()
            status['error'][k] = trace
            _status = (False, 'error', status['error'][k])
    finally:
        if os.getcwd() != cwd:
            os.chdir(cwd)
    return _status


def build_images(images_files, skip_images=None, quiet=False,
                 images=None, dry_run=False, status=None,
                 builder_args=None):
    if not images:
        images = []
    if not skip_images:
        skip_images = []
    if status is None:
        status = copy.deepcopy(_STATUS)
    cwd = os.getcwd()
    for images_file in images_files:
        imagesdata, errors = parse_images_file(images_file)
        if errors:
            status['error']['parsing'] = errors
            break
        for k, img in six.iteritems(index_images(imagesdata)):
            skip = False
            tag = img.get('tag', None)
            if images:
                skip = True
                if k in images or tag in images:
                    skip = False
            if skip_images:
                skip = False
                if k in skip_images or tag in skip_images:
                    skip = True
            if skip:
                status['skip'][k] = True
                _status = (True, 'skip', True)
            else:
                _status = build_image(img, cwd=cwd, builder_args=builder_args,
                                      quiet=quiet,
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
        imagesdata, errors = parse_images_file(images_file)
        if errors:
            status['error']['parsing'] = errors
            break
        for k, img in six.iteritems(index_images(imagesdata)):
            imgf = k
            tag = img.get('tag', None)
            if img['builder_type'] == 'dockerfile' and tag:
                imgf = tag
            status['message'][imgf] = '{0} --images={1}'.format(N, imgf)
    return status


def main():
    args, vargs = parse_cli()
    status = copy.deepcopy(_STATUS)
    setup_logging(level=getattr(logging, vargs['log_level'].upper()))
    log('build started', level='debug')
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
                              quiet=vargs['quiet'],
                              images=vargs['images'],
                              skip_images=vargs['skip_images'],
                              builder_args=vargs['builder_args'],
                              dry_run=vargs['dry_run'])

    rc = len(status['error']) > 0 and 1 or 0
    print_status(status, vargs['quiet'])
    return status, rc


if __name__ == '__main__':
    ret, rc = main()
    sys.exit(rc)
# vim:set et sts=4 ts=4 tw=80:
