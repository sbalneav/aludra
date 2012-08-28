--
-- FUSE functions; functions to support the FUSE filesystem
-- operations of Aludra
--

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
      WHERE path = abspath AND NOT name = '/';
END;
$$ LANGUAGE plpgsql;
