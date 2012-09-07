--
-- Base filesystem.
--

--
-- Root directory
--

INSERT INTO inode
        (st_mode, st_nlink, st_uid, st_gid, st_size, st_rdev, st_atime,   st_mtime,   st_ctime)
 VALUES (16877,   2,        0,      0,      4096,    0,       unixtime(), unixtime(), unixtime());

INSERT INTO tree
 VALUES (currval(pg_get_serial_sequence('inode', 'st_ino')), NULL, '/');
