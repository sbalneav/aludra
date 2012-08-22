create or replace function basename(text) returns text
    as '/usr/lib/postgresql/9.1/lib/pgdirname', 'pgbasename'
    language C strict;

create or replace function dirname(text) returns text
    as '/usr/lib/postgresql/9.1/lib/pgdirname', 'pgdirname'
    language C strict;
