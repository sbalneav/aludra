--
-- FUSE functions; functions to support the FUSE filesystem
-- operations of Aludra
--

--
-- getattr
--

CREATE OR REPLACE FUNCTION getattr (abspath TEXT) RETURNS SETOF inode AS $$
DECLARE
    mypath  TEXT;
    myname  TEXT;
BEGIN
    mypath  := dirname(abspath);
    myname  := basename(abspath);

    RETURN QUERY SELECT *
      FROM inode
      WHERE path = mypath AND name = myname;
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
