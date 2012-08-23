\c filesystem;

CREATE OR REPLACE FUNCTION basename(text) RETURNS TEXT
    AS '/usr/lib/postgresql/9.1/lib/pgdirname', 'pgbasename'
    LANGUAGE C STRICT;

CREATE OR REPLACE function dirname(text) RETURNS TEXT
    AS '/usr/lib/postgresql/9.1/lib/pgdirname', 'pgdirname'
    LANGUAGE c STRICT;
