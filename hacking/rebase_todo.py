#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import, division, print_function


import os
from optparse import OptionParser
from collections import OrderedDict


def rewrite(content):
    todo = OrderedDict()
    for ix, txt in enumerate(content.splitlines()):
        if txt.startswith("#") or not txt.strip():
            todo[txt] = txt + "\n"
        else:
            parts = txt.split(" ")
            action, commit, msg = parts[0], parts[1], " ".join(parts[2:]).strip()
            if msg in todo:
                action = "f"
                todo[msg] += "{} {} {}\n".format(action, commit, msg)
            else:
                todo[msg] = txt + "\n"
    content = "".join(todo.values())
    return content


def main():
    parser = OptionParser()
    parser.add_option("-f", "--file", help="make todo to", metavar="FILE")
    (options, args) = parser.parse_args()
    options.file = os.path.expanduser(options.file)
    with open(options.file) as fic:
        content = rewrite(fic.read())
    with open(options.file, "w") as fic:
        fic.write(content)


if __name__ == "__main__":
    main()
# vim:set et sts=4 ts=4 tw=120:
