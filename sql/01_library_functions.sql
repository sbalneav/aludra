\c filesystem;

CREATE OR REPLACE FUNCTION basename(text) RETURNS TEXT
    AS 'pgdirname', 'pgbasename'
    LANGUAGE C STRICT;

CREATE OR REPLACE function dirname(text) RETURNS TEXT
    AS 'pgdirname', 'pgdirname'
    LANGUAGE c STRICT;
