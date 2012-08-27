--
-- staticallty defined test filesystem
--

--
-- Root directory
--

-- INSERT INTO INODE
-- (path, name, st_dev, st_mode, st_nlink, st_uid, st_gid, st_rdev, st_size, st_blksize, st_blocks, st_atime, st_mtime, st_ctime)
--  VALUES ('/', '/', 0, 16877, 3, 0, 0, 0, 4096, 0, 0, unixtime(), unixtime(), unixtime());

--
-- "test" directory owned by root.
--

-- INSERT INTO INODE
--  (path, name, st_dev, st_mode, st_nlink, st_uid, st_gid, st_rdev, st_size, st_blksize, st_blocks, st_atime, st_mtime, st_ctime)
--  VALUES ('/', 'test', 0, 16877, 3, 0, 0, 0, 4096, 0, 0, unixtime(), unixtime(), unixtime());

--
-- "flarb" directory owned by uid/groupid 1111.
--

-- INSERT INTO INODE
--  (path, name, st_dev, st_mode, st_nlink, st_uid, st_gid, st_rdev, st_size, st_blksize, st_blocks, st_atime, st_mtime, st_ctime)
--  VALUES ('/', 'flarb', 0, 16877, 3, 1111, 1111, 0, 4096, 0, 0, unixtime(), unixtime(), unixtime());

--
-- "foo.txt" file owned by uid/groupid 1111.
--

-- INSERT INTO INODE
-- (path, name, st_dev, st_mode, st_nlink, st_uid, st_gid, st_rdev, st_size, st_blksize, st_blocks, st_atime, st_mtime, st_ctime, fileobjid)
-- VALUES ('/', 'foo.txt', 0, 33188, 3, 1111, 1111, 0, 4096, 0, 0, unixtime(), unixtime(), unixtime(), 1);

-- INSERT INTO fileobj
--    (inode, version, priority, deleted, created, superceded, object)
--     VALUES (4, 1, 1, False, now(), NULL, 'This is a test')
