#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
import yaml
import StringIO
import os
import sys
import json
files = set()
for i in sys.argv[1:]:
    files.add(i)
if not files:
    files.add(os.environ.get('YAML_TEST_FILE', '.gitlab-ci.yml'))
for f in files:
    print('Dumping {0}\n'.format(f))
    data = yaml.load(open(f).read())
    edata = json.loads(json.dumps(data))
    out = StringIO.StringIO()
    yaml.safe_dump(edata,
                   out,
                   allow_unicode=True,
                   default_flow_style=False)
    print(out.getvalue())
# vim:set et sts=4 ts=4 tw=80:
