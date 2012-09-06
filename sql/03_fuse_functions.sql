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
    st_atime INTEGER,
    st_mtime INTEGER,
    st_ctime INTEGER
  );

--
-- getattr
--

CREATE OR REPLACE FUNCTION getattr (abspath TEXT) RETURNS statbuf AS $$
DECLARE
    mypath  TEXT;
    myname  TEXT;
    result  statbuf%ROWTYPE;
BEGIN
    mypath  := dirname(abspath);
    myname  := basename(abspath);

    SELECT INTO result
      inode.st_mode  AS st_mode,
      inode.st_ino   AS st_ino,
      inode.st_dev   AS st_dev,
      inode.st_nlink AS st_nlink,
      inode.st_uid   AS st_uid,
      inode.st_gid   AS st_gid,
      inode.st_size  AS st_size,
      inode.st_atime AS st_atime,
      inode.st_mtime AS st_mtime,
      inode.st_ctime AS st_ctime
      FROM inode
      WHERE path = mypath AND name = myname;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

--
-- readdir
--

CREATE OR REPLACE FUNCTION readdir (abspath TEXT) RETURNS SETOF TEXT AS $$
BEGIN
    RETURN QUERY SELECT (name)
      FROM inode
      WHERE path = abspath AND NOT name = '/' AND deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

--
-- chmod
--

CREATE OR REPLACE FUNCTION chmod (abspath TEXT, mode_t INTEGER) RETURNS INTEGER AS $$
DECLARE
    mypath   TEXT;
    myname   TEXT;
    rowcount INTEGER;
    ENOENT   CONSTANT INTEGER := -2;
BEGIN
    mypath := dirname(abspath);
    myname := basename(abspath);

    UPDATE inode SET st_mode = mode_t
      WHERE path = mypath AND name = myname AND deleted = FALSE;
    GET DIAGNOSTICS rowcount := ROW_COUNT;
    IF rowcount = 0 THEN
        RETURN ENOENT;
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;

--
-- chown
--

CREATE OR REPLACE FUNCTION chown (abspath TEXT, uid_t INTEGER, gid_t INTEGER) RETURNS INTEGER AS $$
DECLARE
    mypath   TEXT;
    myname   TEXT;
    rowcount INTEGER;
    ENOENT   CONSTANT INTEGER := -2;
BEGIN
    mypath := dirname(abspath);
    myname := basename(abspath);

    UPDATE inode SET st_uid = uid_t, st_gid = gid_t
      WHERE path = mypath AND name = myname AND deleted = FALSE;
    GET DIAGNOSTICS rowcount := ROW_COUNT;
    IF rowcount = 0 THEN
        RETURN ENOENT;
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;

--
-- unlink
--

CREATE OR REPLACE FUNCTION unlink (abspath TEXT, uid_t INTEGER, gid_t INTEGER) RETURNS INTEGER AS $$
DECLARE
    mypath   TEXT;
    myname   TEXT;
    myfileobjid INTEGER;
    rowcount INTEGER;
    ENOENT   CONSTANT INTEGER := -2;
BEGIN
    mypath := dirname(abspath);
    myname := basename(abspath);

    SELECT inode.fileobjid INTO myfileobjid
      FROM inode
      WHERE path = mypath AND name = myname AND deleted = FALSE;
    GET DIAGNOSTICS rowcount := ROW_COUNT;
    IF rowcount = 0 THEN
        RETURN ENOENT;
    END IF;

    DELETE FROM inode
      WHERE path = mypath AND name = myname AND deleted = FALSE;
    DELETE FROM fileobj
      WHERE fileobjid = myfileobjid;
    RETURN 0;
END;
$$ LANGUAGE plpgsql;

--
-- mknod
--

CREATE OR REPLACE FUNCTION mknod (abspath TEXT, mode_t INTEGER, dev_t INTEGER, uid_t INTEGER, gid_t INTEGER) RETURNS SETOF BYTEA AS $$
DECLARE
    mypath   TEXT;
    myname   TEXT;
    S_IFREG  CONSTANT INTEGER := 32768;
    myinode  INTEGER;
    myfileobjid  INTEGER;
BEGIN
    mypath := dirname(abspath);
    myname := basename(abspath);

    INSERT INTO inode
      (path,   name,   deleted, st_dev, st_mode, st_nlink, st_uid, st_gid, st_rdev, st_size, st_blksize, st_blocks, st_atime, st_mtime, st_ctime)
      VALUES
      (mypath, myname, FALSE,   dev_t,  mode_t,  1,        uid_t,  gid_t,  0,       0,       0,          0,         unixtime(), unixtime(), unixtime());

    SELECT currval(pg_get_serial_sequence('inode', 'st_ino')) INTO myinode;

    INSERT INTO fileobj
      (inode, version, priority, deleted, created, superceded, object)
      VALUES
      (myinode, 1, 1, FALSE, now(), NULL, NULL);

    SELECT currval(pg_get_serial_sequence('fileobj', 'fileobjid')) INTO myfileobjid;

    UPDATE inode SET fileobjid = myfileobjid
      WHERE st_ino = myinode;

    RETURN QUERY SELECT (object)
      FROM fileobj
      WHERE fileobjid = myfileobjid;
END;
$$ LANGUAGE plpgsql;
--
-- open
--

CREATE OR REPLACE FUNCTION open (abspath TEXT) RETURNS SETOF BYTEA AS $$
DECLARE
    mypath   TEXT;
    myname   TEXT;
BEGIN
    mypath := dirname(abspath);
    myname := basename(abspath);

    RETURN QUERY SELECT (object)
      FROM fileobj
      WHERE fileobjid = (SELECT fileobjid FROM inode WHERE path = mypath AND name = myname AND deleted = FALSE);
END;
$$ LANGUAGE plpgsql;

--
-- release
--

CREATE OR REPLACE FUNCTION release (abspath TEXT, data BYTEA) RETURNS INTEGER AS $$
DECLARE
    mypath   TEXT;
    myname   TEXT;
    olength  INTEGER;
BEGIN
    mypath := dirname(abspath);
    myname := basename(abspath);

    olength := octet_length(data);
    UPDATE fileobj SET object = data
      WHERE fileobjid = (SELECT fileobjid FROM inode WHERE path = mypath AND name = myname AND deleted = FALSE);
    UPDATE inode SET st_size = olength, st_atime = unixtime()
      WHERE path = mypath AND name = myname AND deleted = FALSE;
    RETURN 0;
END;
$$ LANGUAGE plpgsql;
