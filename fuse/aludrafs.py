#!/usr/bin/env python

import psycopg2

import fsutils
import dbutils

if __name__ == '__main__':
    dbconnect = fsutils.readConfig('mount1')
    print(dbconnect)

    dbHandle = conn = psycopg2.connect(dbconnect)

    dbutils.checkdb(dbHandle)
