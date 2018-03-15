#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
import sys
import pstats
aaa = pstats.Stats(sys.argv[1])
aaa.sort_stats('cumulative')
aaa.print_stats()
# vim:set et sts=4 ts=4 tw=80:
