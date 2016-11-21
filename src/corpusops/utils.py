#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import collections


class CorpusOpsException(Exception):
    """."""


def update_no_list(dest, upd, recursive_update=True):
    '''
    Recursive version of the default dict.update

    Merges upd recursively into dest
    But instead of merging lists, it overrides them from target dict
    '''
    if (not isinstance(dest, collections.Mapping)) \
            or (not isinstance(upd, collections.Mapping)):
        raise TypeError('Cannot update using non-dict '
                        'types in dictupdate.update()')
    updkeys = list(upd.keys())
    if not set(list(dest.keys())) & set(updkeys):
        recursive_update = False
    if recursive_update:
        for key in updkeys:
            val = upd[key]
            try:
                dest_subkey = dest.get(key, None)
            except AttributeError:
                dest_subkey = None
            if isinstance(dest_subkey, collections.Mapping) \
                    and isinstance(val, collections.Mapping):
                ret = update_no_list(dest_subkey, val)
                dest[key] = ret
            else:
                dest[key] = upd[key]
        return dest
    else:
        try:
            dest.update(upd)
        except AttributeError:
            # this mapping is not a dict
            for k in upd:
                dest[k] = upd[k]
        return dest


def dictupdate(dict1, dict2):
    '''
    Merge two dictionnaries recursively

    test::

      salt '*' mc_utils.dictupdate '{foobar:
                  {toto: tata, toto2: tata2},titi: tutu}'
                  '{bar: toto, foobar: {toto2: arg, toto3: arg2}}'
      ----------
      bar:
          toto
      foobar:
          ----------
          toto:
              tata
          toto2:
              arg
          toto3:
              arg2
      titi:
          tutu
    '''
    if not isinstance(dict1, dict):
        raise CorpusOpsException(
            'dictupdate 1st argument is not a dictionnary!')
    if not isinstance(dict2, dict):
        raise CorpusOpsException(
            'dictupdate 2nd argument is not a dictionnary!')
    return update_no_list(dict1, dict2)

# vim:set et sts=4 ts=4 tw=80:
