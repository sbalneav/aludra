\c filesystem;

--
-- fileobj table
--

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

CREATE TABLE inode
  (
    inode     SERIAL,
    path      TEXT,
    name      TEXT,
    mode      INTEGER,
    uid       INTEGER,
    gid       INTEGER,
    ctime     INTEGER,
    mtime     INTEGER,
    atime     INTEGER,
    size      INTEGER,
    fileobjid INTEGER
  );
