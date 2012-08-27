#!/usr/bin/env python

import psycopg2
import fuse
import errno

import fsutils
import dbutils

fuse.fuse_python_api = (0, 2)

class AludraFS(fuse.Fuse):
    def __init__(self, *args, **kw):
        fuse.Fuse.__init__(self, *args, **kw)

        dbconnect = fsutils.readConfig(self.db)

        self.conn = psycopg2.connect(dbconnect)
        self.cursor = self.conn.cursor()

    def getattr(self, path):
        self.cursor.callproc('getattr', path)
        result = self.cursor.fetchone()
        if not result:
            return -errno.ENOENT
        return st

    def readdir(self, path, offset):
        dirents = [ '.', '..' ]
        for r in dirents:
            yield fuse.Direntry(r)

    def mknod(self, path, mode, dev):
        return 0

    def unlink(self, path):
        return 0

    def read(self, path, size, offset):
        return 0

    def write(self, path, buf, offset):
        return 0

    def release(self, path, flags):
        return 0

    def open(self, path, flags):
        return 0

    def truncate(self, path, size):
        return 0

    def utime(self, path, times):
        return 0

    def mkdir(self, path, mode):
        return 0

    def rmdir(self, path):
        return 0

    def rename(self, pathfrom, pathto):
        return 0

    def fsync(self, path, isfsyncfile):
        return 0

def main():
    usage="""
        AludraFS: A filesystem interface to the Aludra Document Management
                  system.
    """ + fuse.Fuse.fusage

    server = AludraFS(version="%prog " + fuse.__version__,
                 usage=usage, dash_s_do='setsingle')

    # Disable multithreading for now.
    server.multithreaded = False

    server.parser.add_option(mountopt="db", metavar="ALUDRA_DB", default='aludra',
                        help="Database to connect to in aludra.conf [default: %default]")

    server.parse(errex=1)

    # By default, allow others access
    server.fuse_args.add('allow_other')
    server.main()

if __name__ == '__main__':
    main()
