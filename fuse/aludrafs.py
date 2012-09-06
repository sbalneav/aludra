#!/usr/bin/env python

import psycopg2
import fuse
import errno
import tempfile

import fsutils
import dbutils

fuse.fuse_python_api = (0, 2)

#
# MyStat class:
#
# Extend fuse Stat class with initializer to populate structure from stat
# tuple.
#

class MyStat(fuse.Stat):
    def __init__(self, stattuple):
        self.st_mode  = stattuple[0]
        self.st_ino   = stattuple[1]
        self.st_dev   = stattuple[2]
        self.st_nlink = stattuple[3]
        self.st_uid   = stattuple[4]
        self.st_gid   = stattuple[5]
        self.st_size  = stattuple[6]
        self.st_atime = stattuple[7]
        self.st_mtime = stattuple[8]
        self.st_ctime = stattuple[9]

#
# Main AludraFS fuse class.
#

class AludraFS(fuse.Fuse):
    def __init__(self, *args, **kw):
        fuse.Fuse.__init__(self, *args, **kw)

        self.db = 'aludra'

        dbconnect = fsutils.readConfig(self.db)
        self.conn = psycopg2.connect(dbconnect)
        self.cursor = self.conn.cursor()
        self.filecache = {}

    def getattr(self, path):
        self.cursor.callproc('getattr', [path])
        for result in self.cursor:
            pass
        if not result or result[1] == None:
            return -errno.ENOENT
        st = MyStat(result)
        return st

    def readdir(self, path, offset):
        self.cursor.callproc('readdir', [path])
        yield fuse.Direntry('.')
        yield fuse.Direntry('..')
        for entry in self.cursor:
            yield fuse.Direntry(entry[0])

    def chmod(self, path, mode):
        self.cursor.callproc('chmod', [path, mode])
        for ret in self.cursor:
            pass
        return ret[0]

    def chown(self, path, uid, gid):
        self.cursor.callproc('chown', [path, uid, gid])
        for ret in self.cursor:
            pass
        return ret[0]

    def mknod(self, path, mode, dev):
        uid = self.GetContext()['uid']
        gid = self.GetContext()['gid']
        self.cursor.callproc('mknod', [path, mode, dev, uid, gid])
        for ret in self.cursor:
            pass
        return ret[0]

    def unlink(self, path):
        return 0

    def open(self, path, flags):
        self.cursor.callproc('open', [path])
        for data in self.cursor:
            self.filecache[path] = tempfile.TemporaryFile()
            self.filecache[path].write(data[0])
        return 0

    def read(self, path, size, offset):
        self.filecache[path].seek(offset)
        return self.filecache[path].read(size)

    def write(self, path, buf, offset):
        self.filecache[path].seek(offset)
        self.filecache[path].write(buf)
        return len(buf)
        return 0

    def release(self, path, flags):
        self.filecache[path].seek(0)
        data = self.filecache[path].read()
        self.filecache[path].close()
        del self.filecache[path]
        self.cursor.callproc('release', [path, data])
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

    server.parse(values=server, errex=1)

    # By default, allow others access
    # server.fuse_args.add('allow_other')
    server.main()

if __name__ == '__main__':
    main()
