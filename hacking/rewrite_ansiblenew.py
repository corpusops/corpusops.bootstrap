#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import ruamel.yaml
import textwrap
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
import ruamel.yaml
from threading import Thread
from subprocess import PIPE, Popen
from collections import OrderedDict
from ruamel.yaml.scalarstring import DoubleQuotedScalarString


try:
    from queue import Queue
except ImportError:
    from Queue import Queue


from ruamel.yaml.representer import (
    RoundTripRepresenter,
    CommentedOrderedMap,
    CommentedMap,
)
for typ in [
    OrderedDict, dict, CommentedMap, CommentedOrderedMap
]:
    RoundTripRepresenter.add_representer(
        typ, RoundTripRepresenter.represent_dict)

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
_LOGGER = 'cops.{0}'.format(BN)
_LOGGER_FMT = '%(asctime)s:%(levelname)s:%(name)s:%(message)s'
_LOGGER_DFMT = '%m/%d/%Y %I:%M:%S %p'
_HELP = '''\
        Rewrite tasks files for new ansible forms
Main usage:
    - {N} taskfilepath1 taskfilepath2

'''.format(N=N)

registry_knobs = [
    "cops_do_format_resolve", "cops_computed_defaults",
    "cops_flavors", "cops_sub_os_append", "cops_lowered",
    "cops_knobs", "cops_sub_namespaces"]

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


def parse_cli():
    parser = argparse.ArgumentParser(usage=_HELP)
    parser.add_argument(
        'tasksfiles',
        nargs='*',
        default=[],
        help='tasksfiles to rewrite')
    parser.add_argument(
        '--log-level',
        default=os.environ.get('LOGLEVEL', 'info'),
        help='loglevel')
    args = parser.parse_args()
    return args, vars(args), parser


def represent_dict_order(self, data):
    self.represent_mapping('tag:yaml.org,2002:map', data.items())


class Acfg(object):
    def __init__(self, cfg, autoload=True):
        self.cfg = cfg
        self.orig = None
        self.data = OrderedDict()
        yaml = self.yaml = ruamel.yaml.YAML(typ='rt')
        yaml.allow_duplicate_keys = True
        yaml.explicit_start = True
        # yaml.default_style = '"'
        yaml.preserve_quotes = True
        yaml.default_flow_style = True
        yaml.line_break = 0
        yaml.explicit_start = True
        yaml.indent(sequence=2)
        yaml.width = 8000
        yaml.canonical = False
        if autoload:
            self.load()

    @property
    def exists(self):
        return os.path.exists(self.cfg)

    def load(self):
        if self.exists:
            with open(self.cfg) as fic:
                self.orig = fic.read()
                # self.yaml.width = max([len(a) for a in self.orig.splitlines()])
                self.data = self.yaml.load(self.orig)

    def write(self, ncfg=None, transform=None):
        if not ncfg:
            ncfg = self.cfg
        if not os.path.exists(D(ncfg)):
            os.makedirs(D(ncfg))
        with open(ncfg, 'w') as fic:
            # self.yaml.compact(seq_seq=False, seq_map=False)
            self.yaml.dump(self.data, fic, transform=transform)


def transform_when(content, *args, **kw):
    lines = []
    # content = content.replace('\\\n', 'REPLACEANTISLASH')
    # content = re.sub(r'REPLACEANTISLASH[^\\]+\\', '', content)
    for line in content.splitlines():
        if re.search('when: "\(.*\)"$', line):
            for splitter in ' or', ' and':
                line = '{0}\n'.format(splitter).join(
                    [(ix < 1 and a or '{1}{0}'.format(a, (1+line.find('"')) * " "))
                     for ix, a in enumerate(line.split(splitter))])
        lines.append(line)
    return "\n".join(lines)


def rewrite_taskfile(taskfile_path):
    cfg = Acfg(taskfile_path)
    taskfile_name = os.path.split(taskfile_path)[-1]
    rewrite = False
    S = ruamel.yaml.scalarstring.PreservedScalarString
    if isinstance(cfg.data, list):
        for item in cfg.data:
            pkg = item.get('package', None)
            if not pkg:
                continue
            try:
                toinstall = item['loop']
            except KeyError:
                continue
            if re.match('^{{[^}]+}}$', pkg['name']):
                pkg['name'] = toinstall
                item.pop('loop')
                rewrite = True
    if rewrite:
        log('Rewrite {}'.format(taskfile_path))
        cfg.write(transform=transform_when)


def main():
    args, vargs, parser = parse_cli()
    setup_logging(level=getattr(logging, vargs['log_level'].upper()))
    log('build started', level='debug')
    tasksfiles = []
    cwd = os.getcwd()
    for taskfile in args.tasksfiles:
        if os.path.sep not in taskfile:
            taskfile = J(cwd, taskfile)
        tasksfiles.append(taskfile)
    for taskfile in tasksfiles:
        rewrite_taskfile(taskfile)


if __name__ == '__main__':
    main()
# vim:set et sts=4 ts=4 tw=80:
