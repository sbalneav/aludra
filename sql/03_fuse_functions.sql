--
-- FUSE functions; functions to support the FUSE filesystem
-- operations of Aludra
--

--
-- Error numbers: to be cut and paste into functions as needed.
-- Numbers are negative due to fuse calling conventions.
--

-- EPERM   CONSTANT INTEGER := -1
-- ENOENT  CONSTANT INTEGER := -2
-- ESRCH   CONSTANT INTEGER := -3
-- EINTR   CONSTANT INTEGER := -4
-- EIO     CONSTANT INTEGER := -5
-- ENXIO   CONSTANT INTEGER := -6
-- E2BIG   CONSTANT INTEGER := -7
-- ENOEXEC CONSTANT INTEGER := -8
-- EBADF   CONSTANT INTEGER := -9
-- ECHILD  CONSTANT INTEGER := -10
-- EAGAIN  CONSTANT INTEGER := -11
-- ENOMEM  CONSTANT INTEGER := -12
-- EACCES  CONSTANT INTEGER := -13
-- EFAULT  CONSTANT INTEGER := -14
-- ENOTBLK CONSTANT INTEGER := -15
-- EBUSY   CONSTANT INTEGER := -16
-- EEXIST  CONSTANT INTEGER := -17
-- EXDEV   CONSTANT INTEGER := -18
-- ENODEV  CONSTANT INTEGER := -19
-- ENOTDIR CONSTANT INTEGER := -20
-- EISDIR  CONSTANT INTEGER := -21
-- EINVAL  CONSTANT INTEGER := -22
-- ENFILE  CONSTANT INTEGER := -23
-- EMFILE  CONSTANT INTEGER := -24
-- ENOTTY  CONSTANT INTEGER := -25
-- ETXTBSY CONSTANT INTEGER := -26
-- EFBIG   CONSTANT INTEGER := -27
-- ENOSPC  CONSTANT INTEGER := -28
-- ESPIPE  CONSTANT INTEGER := -29
-- EROFS   CONSTANT INTEGER := -30
-- EMLINK  CONSTANT INTEGER := -31
-- EPIPE   CONSTANT INTEGER := -32
-- EDOM    CONSTANT INTEGER := -33
-- ERANGE  CONSTANT INTEGER := -34
-- EDEADLK CONSTANT INTEGER := -35
-- ENAMETOOLONG	CONSTANT INTEGER := -36
-- ENOLCK  CONSTANT INTEGER := -37
-- ENOSYS  CONSTANT INTEGER := -38
-- ENOTEMPTY CONSTANT INTEGER := -39

--
-- defines from stat.h
--

-- S_IFMT   CONSTANT INTEGER := 61440
-- S_IFSOCK CONSTANT INTEGER := 49152
-- S_IFLNK  CONSTANT INTEGER := 40960
-- S_IFREG  CONSTANT INTEGER := 32768
-- S_IFBLK  CONSTANT INTEGER := 24576
-- S_IFDIR  CONSTANT INTEGER := 16384
-- S_IFCHR  CONSTANT INTEGER := 8192
-- S_IFIFO  CONSTANT INTEGER := 4096
-- S_ISUID  CONSTANT INTEGER := 2048
-- S_ISGID  CONSTANT INTEGER := 1024
-- S_ISVTX  CONSTANT INTEGER := 512
-- S_IRWXU  CONSTANT INTEGER := 448
-- S_IRUSR  CONSTANT INTEGER := 256
-- S_IWUSR  CONSTANT INTEGER := 128
-- S_IXUSR  CONSTANT INTEGER := 64
-- S_IRWXG  CONSTANT INTEGER := 56
-- S_IRGRP  CONSTANT INTEGER := 32
-- S_IWGRP  CONSTANT INTEGER := 16
-- S_IXGRP  CONSTANT INTEGER := 8
-- S_IRWXO  CONSTANT INTEGER := 7
-- S_IROTH  CONSTANT INTEGER := 4
-- S_IWOTH  CONSTANT INTEGER := 2
-- S_IXOTH  CONSTANT INTEGER := 1

DROP TYPE IF EXISTS statbuf CASCADE;
CREATE TYPE statbuf AS
  (
    st_mode  INTEGER,
    st_ino   INTEGER,
    st_dev   INTEGER,
    st_nlink INTEGER,
    st_uid   INTEGER,
    st_gid   INTEGER,
    st_size  INTEGER,
    st_rdev  INTEGER,
    st_atime INTEGER,
    st_mtime INTEGER,
    st_ctime INTEGER
  );

--
-- find_inode
--

CREATE OR REPLACE FUNCTION find_inode (abspath TEXT) RETURNS INTEGER AS $$
DECLARE
    mypath  TEXT;
    myname  TEXT;
    inode   INTEGER;
    pinode  INTEGER;
BEGIN
    mypath  := dirname(abspath);
    myname  := basename(abspath);

    IF myname = '/' AND mypath = '/' THEN
      SELECT INTO inode st_ino FROM tree WHERE name = '/' AND parent IS NULL;
      RETURN inode;
    ELSE
      pinode := find_inode(mypath);
      SELECT INTO inode st_ino FROM tree WHERE name = myname and parent = pinode;
      RETURN inode;
    END IF;
END;
$$ LANGUAGE plpgsql;

--
-- find_inode_direct
--

CREATE OR REPLACE FUNCTION find_inode_direct (abspath TEXT) RETURNS INTEGER AS $$
DECLARE
    inode   INTEGER;
BEGIN
    SELECT INTO inode st_ino FROM tree WHERE fullpath = abspath;
    RETURN inode;
END;
$$ LANGUAGE plpgsql;

--
-- getattr
--

CREATE OR REPLACE FUNCTION fuse_getattr (abspath TEXT) RETURNS statbuf AS $$
DECLARE
    myinode INTEGER;
    result  statbuf%ROWTYPE;
BEGIN
    myinode := find_inode_direct(abspath);

    SELECT INTO result
      inode.st_mode  AS st_mode,
      inode.st_ino   AS st_ino,
      0              AS st_dev,
      inode.st_nlink AS st_nlink,
      inode.st_uid   AS st_uid,
      inode.st_gid   AS st_gid,
      inode.st_size  AS st_size,
      inode.st_rdev  AS st_rdev,
      inode.st_atime AS st_atime,
      inode.st_mtime AS st_mtime,
      inode.st_ctime AS st_ctime
      FROM inode
      WHERE st_ino = myinode;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

--
-- readdir
--

CREATE OR REPLACE FUNCTION fuse_readdir (abspath TEXT) RETURNS SETOF TEXT AS $$
DECLARE
    myinode INTEGER;
BEGIN
    myinode := find_inode_direct(abspath);

    RETURN QUERY SELECT name
      FROM tree
      WHERE parent = myinode;
END;
$$ LANGUAGE plpgsql;

--
-- chmod
--

CREATE OR REPLACE FUNCTION fuse_chmod (abspath TEXT, mode_t INTEGER) RETURNS INTEGER AS $$
DECLARE
    myinode  INTEGER;
    ENOENT   CONSTANT INTEGER := -2;
BEGIN
    myinode := find_inode_direct(abspath);

    IF myinode = NULL THEN
        RETURN ENOENT;
    END IF;

    UPDATE inode SET st_mode = mode_t
      WHERE st_ino = myinode;
    RETURN 0;
END;
$$ LANGUAGE plpgsql;

--
-- chown
--

CREATE OR REPLACE FUNCTION fuse_chown (abspath TEXT, uid_t INTEGER, gid_t INTEGER) RETURNS INTEGER AS $$
DECLARE
    myinode  INTEGER;
    ENOENT   CONSTANT INTEGER := -2;
BEGIN
    myinode := find_inode_direct(abspath);

    IF myinode = NULL THEN
        RETURN ENOENT;
    END IF;

    UPDATE inode SET st_uid = uid_t, st_gid = gid_t
      WHERE st_ino = myinode;
    RETURN 0;
END;
$$ LANGUAGE plpgsql;

--
-- unlink
--

CREATE OR REPLACE FUNCTION fuse_unlink (abspath TEXT, uid_t INTEGER, gid_t INTEGER) RETURNS INTEGER AS $$
DECLARE
    myinode  INTEGER;
    myfileobjid INTEGER;
    ENOENT   CONSTANT INTEGER := -2;
BEGIN
    myinode := find_inode_direct(abspath);

    IF myinode = NULL THEN
        RETURN ENOENT;
    END IF;

    DELETE FROM inode
      WHERE st_ino = myinode;
    DELETE FROM fileobj
      WHERE st_ino = myinode;
    DELETE FROM tree
      WHERE st_ino = myinode;
    RETURN 0;
END;
$$ LANGUAGE plpgsql;

--
-- mknod
--

CREATE OR REPLACE FUNCTION fuse_mknod (abspath TEXT, mode_t INTEGER, dev_t INTEGER, uid_t INTEGER, gid_t INTEGER) RETURNS INTEGER AS $$
DECLARE
    myname      TEXT;
    S_IFREG     CONSTANT INTEGER := 32768;
    ENOENT      CONSTANT INTEGER := -2;
    myinode     INTEGER;
    parentino   INTEGER;
    myfileobjid INTEGER;
    mymode      INTEGER;
BEGIN
    parentino  := find_inode_direct(dirname(abspath));
    myname     := basename(abspath);

    IF parentino = NULL then
        RETURN ENOENT;
    END IF;

    mymode := mode_t | S_IFREG;

    INSERT INTO inode
      (st_mode, st_nlink, st_uid, st_gid, st_size, st_rdev, st_atime,   st_mtime,   st_ctime)
      VALUES
      (mymode,  1,        uid_t,  gid_t,  0,       dev_t,   unixtime(), unixtime(), unixtime());

    SELECT currval(pg_get_serial_sequence('inode', 'st_ino')) INTO myinode;

    INSERT INTO tree
      (st_ino, parent, name, fullpath)
      VALUES (myinode, parentino, myname, abspath);

    INSERT INTO fileobj
      (st_ino,  version, priority, deleted, created, superceded, object)
      VALUES
      (myinode, 1,       1,        FALSE,   now(),   NULL,       NULL);

    SELECT currval(pg_get_serial_sequence('fileobj', 'fileobjid')) INTO myfileobjid;

    UPDATE inode SET fileobjid = myfileobjid
      WHERE st_ino = myinode;

    RETURN 0;
END;
$$ LANGUAGE plpgsql;

--
-- mkdir
--

CREATE OR REPLACE FUNCTION fuse_mkdir (abspath TEXT, mode_t INTEGER, uid_t INTEGER, gid_t INTEGER) RETURNS INTEGER AS $$
DECLARE
    myname      TEXT;
    S_IFDIR     CONSTANT INTEGER := 16384;
    ENOENT      CONSTANT INTEGER := -2;
    myinode     INTEGER;
    parentino   INTEGER;
    myfileobjid INTEGER;
    mymode      INTEGER;
BEGIN
    parentino  := find_inode_direct(dirname(abspath));
    myname     := basename(abspath);

    IF parentino = NULL then
        RETURN ENOENT;
    END IF;

    mymode := mode_t | S_IFDIR;

    INSERT INTO inode
      (st_mode, st_nlink, st_uid, st_gid, st_size, st_rdev, st_atime,   st_mtime,   st_ctime)
      VALUES
      (mymode,  2,        uid_t,  gid_t,  4096,    0,       unixtime(), unixtime(), unixtime());

    SELECT currval(pg_get_serial_sequence('inode', 'st_ino')) INTO myinode;

    INSERT INTO tree
      (st_ino, parent, name, fullpath)
      VALUES (myinode, parentino, myname, abspath);

    UPDATE inode SET st_nlink = st_nlink + 1
      WHERE st_ino = parentino;

    RETURN 0;
END;
$$ LANGUAGE plpgsql;

--
-- rmdir
--

CREATE OR REPLACE FUNCTION fuse_rmdir (abspath TEXT) RETURNS INTEGER AS $$
DECLARE
    ENOENT    CONSTANT INTEGER := -2;
    ENOTEMPTY CONSTANT INTEGER := -39;
    myinode   INTEGER;
    parentino INTEGER;
    filecount INTEGER;
BEGIN
    parentino  := find_inode_direct(dirname(abspath));
    myinode    := find_inode_direct(abspath);

    IF myinode = NULL THEN
        RETURN ENOENT;
    END IF;

    SELECT INTO filecount count(st_ino) FROM tree
      WHERE parent = myinode;

    IF filecount > 0 THEN
        RETURN ENOTEMPTY;
    END IF;

    DELETE FROM inode
      WHERE st_ino = myinode;

    DELETE FROM tree
      WHERE st_ino = myinode;

    UPDATE inode SET st_nlink = st_nlink - 1
      WHERE st_ino = parentino;

    RETURN 0;
END;
$$ LANGUAGE plpgsql;

--
-- open
--

CREATE OR REPLACE FUNCTION fuse_open (abspath TEXT) RETURNS SETOF BYTEA AS $$
DECLARE
    myinode INTEGER;
BEGIN
    myinode := find_inode_direct(abspath);

    RETURN QUERY SELECT object
      FROM fileobj
      WHERE st_ino = myinode;
END;
$$ LANGUAGE plpgsql;

--
-- release
--

CREATE OR REPLACE FUNCTION fuse_release (abspath TEXT, data BYTEA) RETURNS INTEGER AS $$
DECLARE
    olength INTEGER;
    myinode INTEGER;
BEGIN
    myinode := find_inode_direct(abspath);
    olength := octet_length(data);

    UPDATE fileobj SET object = data
      WHERE st_ino = myinode;
    UPDATE inode SET st_size = olength, st_atime = unixtime()
      WHERE st_ino = myinode;
    RETURN 0;
END;
$$ LANGUAGE plpgsql;

--
-- truncate
--

CREATE OR REPLACE FUNCTION fuse_truncate (abspath TEXT, size_t INTEGER) RETURNS INTEGER AS $$
DECLARE
    myinode  INTEGER;
    trimmed  BYTEA;
    ENOENT   CONSTANT INTEGER := -2;
BEGIN
    myinode := find_inode_direct(abspath);

    IF myinode = NULL THEN
        RETURN ENOENT;
    END IF;

    UPDATE fileobj SET object = substring(object from 1 for size_t)
      where st_ino = myinode;
    UPDATE inode SET st_size = size_t, st_mtime = unixtime(), st_ctime = unixtime()
      WHERE st_ino = myinode;
    RETURN 0;
END;
$$ LANGUAGE plpgsql;

--
-- utime
--

CREATE OR REPLACE FUNCTION fuse_utime (abspath TEXT, atime INTEGER, mtime INTEGER) RETURNS INTEGER AS $$
DECLARE
    myinode  INTEGER;
    trimmed  BYTEA;
    ENOENT   CONSTANT INTEGER := -2;
BEGIN
    myinode := find_inode_direct(abspath);

    IF myinode = NULL THEN
        RETURN ENOENT;
    END IF;

    UPDATE inode SET st_atime = atime, st_mtime = mtime
      where st_ino = myinode;
    RETURN 0;
END;
$$ LANGUAGE plpgsql;
