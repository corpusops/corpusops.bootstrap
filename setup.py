#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import re
import sys
import traceback
from setuptools import setup, find_packages

try:
    import pip
    HAS_PIP = True
except:
    HAS_PIP = False

def read(*rnames):
    return open(
        os.path.join(".", *rnames)
    ).read()
READMES = [a
           for a in ['README', 'README.rst',
                     'README.md', 'README.txt']
           if os.path.exists(a)]
long_description = "\n\n".join(READMES)
classifiers = [
    "Programming Language :: Python",
    "Topic :: Software Development"]

name = 'corpusops'
version = '1.0'
src_dir = 'src'
install_requires = []
extra_requires = {}
candidates = {}
entry_points = {
    # z3c.autoinclude.plugin": ["target = plone"],
    "console_scripts": [
        "ansible_rewrie_meta = corpusops.ansible_rewrite_meta:main"],
}
setup(name=name,
      version=version,
      namespace_packages=[],
      description=name,
      long_description=long_description,
      classifiers=classifiers,
      keywords="",
      author="foo",
      author_email="foo@foo.com",
      url="http://www.makina-corpus.com",
      license="GPL",
      packages=find_packages(src_dir),
      package_dir={"": src_dir},
      include_package_data=True,
      install_requires=install_requires,
      extras_require=extra_requires,
      entry_points=entry_points)
# vim:set ft=python:
