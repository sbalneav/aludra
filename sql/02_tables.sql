--
-- fileobj table
--

DROP TABLE fileobj;
CREATE TABLE fileobj
  (
    fileobjid  SERIAL,
    inode      INTEGER,
    version    INTEGER,
    priority   INTEGER,
    deleted    BOOLEAN,
    created    TIMESTAMP,
    superceded TIMESTAMP,
    object     BYTEA
  );

--
-- inode table
--

DROP TABLE inode;
CREATE TABLE inode
  (
    st_ino     SERIAL,
    path       TEXT,
    name       TEXT,
    st_dev     INTEGER,
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
    st_ctime   INTEGER,
    fileobjid  INTEGER
  );
