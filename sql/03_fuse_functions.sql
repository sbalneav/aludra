--
-- FUSE functions; functions to support the FUSE filesystem
-- operations of Aludra
--

DROP TYPE statbuf CASCADE;
CREATE TYPE statbuf AS
  (
    st_dev     INTEGER,
    st_ino     INTEGER,
    st_mode    INTEGER,
    st_nlink   INTEGER,
    st_uid     INTEGER,
    st_gid     INTEGER,
    st_rdev    INTEGER,
    st_size    INTEGER,
    st_blksize INTEGER,
    st_blocks  INTEGER,
    st_atime   INTEGER,
    st_mtime   INTEGER,
    st_ctime   INTEGER
  );

--
-- getattr
--

CREATE OR REPLACE FUNCTION getattr (abspath TEXT) RETURNS SETOF statbuf AS $$
DECLARE
    mypath  TEXT;
    myname  TEXT;
    ret     statbuf%ROWTYPE;
BEGIN
    mypath  := dirname(path);
    myname  := basename(path);

    SELECT (st_dev, st_ino, st_mode, st_nlink, st_uid, st_gid, st_rdev, st_size, st_blksize, st_blocks, st_atime, st_mtime, st_ctime)
      INTO ret
      FROM inode
      WHERE path = mypath AND name = myname;

    RETURN NEXT ret;
END;
$$ LANGUAGE plpgsql;

--
-- readdir
--

CREATE OR REPLACE FUNCTION readdir (abspath TEXT) RETURNS SETOF TEXT AS $$
BEGIN
    SELECT (name)
      FROM inode
      WHERE path = abspath;
END;
$$ LANGUAGE plpgsql;
