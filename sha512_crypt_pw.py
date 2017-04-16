#!/usr/bin/env python
# Armorless-Visage 2017 (c) BSD 3 Clause

from crypt import crypt
from os import urandom
from sys import stderr, exit
from argparse import ArgumentParser
from base64 import b64encode


# simple linux password generator using sha256

def getargs():
    p = ArgumentParser()
    p.add_argument('password', help='cleartext password to hash', type=str)
    
    args = p.parse_args()

    return args.password


def genhash(cleartext):
    # this below encodes 18 Bytes (padding == b64 happens @ 16B) of csprng into
    # an alternate base64 alphabet (crypt.crypt likes './a-zA-Z0-9') as salt
    b64salt = str(b64encode(urandom(18), './'))
    salt_charset = (
            './abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')

    # double check salt is ok
    for char in b64salt:
        if char in salt_charset:
            pass
        else:
            stderr.write('Character found in salt that is not in approved charset\n')
            stderr.write("''Character:" + char + "''"+ '\n')
            exit(1)
            
    return str(crypt(cleartext, str('$6$' + b64salt)))

if __name__ == '__main__':
    try:
        pw = str(getargs())
        print genhash(pw)
        exit(0)
    except (KeyboardInterrupt, SystemExit):
        raise


