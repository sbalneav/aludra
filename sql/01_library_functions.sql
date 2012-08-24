CREATE OR REPLACE FUNCTION basename(text) RETURNS TEXT
    AS 'pglibaludra', 'pgbasename'
    LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION dirname(text) RETURNS TEXT
    AS 'pglibaludra', 'pgdirname'
    LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION unixtime() RETURNS INTEGER
    AS 'pglibaludra', 'pgtime'
    LANGUAGE C STRICT;
