--
-- tree table
--

DROP TABLE tree;
CREATE TABLE tree
  (
    st_ino     INTEGER,
    parent     INTEGER,
    name       TEXT
  );

--
-- inode table
--

DROP TABLE inode;
CREATE TABLE inode
  (
    st_ino     SERIAL,
    st_mode    INTEGER,
    st_nlink   INTEGER,
    st_uid     INTEGER,
    st_gid     INTEGER,
    st_size    INTEGER,
    st_rdev    INTEGER,
    st_atime   INTEGER,
    st_mtime   INTEGER,
    st_ctime   INTEGER,
    fileobjid  INTEGER
  );

--
-- fileobj table
--

DROP TABLE fileobj;
CREATE TABLE fileobj
  (
    fileobjid  SERIAL,
    st_ino     INTEGER,
    version    INTEGER,
    priority   INTEGER,
    deleted    BOOLEAN,
    created    TIMESTAMP,
    superceded TIMESTAMP,
    object     BYTEA
  );
