#!/usr/bin/env python

import psycopg2

def checkdb(dbHandle):
    cursor = dbHandle.cursor()
    cursor.execute("select * from information_schema.tables where table_name=%s",
            ('dbversion',))
    result = bool(cursor.rowcount)

    if result is True:
        print('Table Exists')
    else:
        print('No dbversion table')
