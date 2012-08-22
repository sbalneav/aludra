/*
 * pgdirname.c
 */

#include <postgres.h>
#include <fmgr.h>
#include <libgen.h>

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

PG_FUNCTION_INFO_V1 (pgdirname);

Datum
pgdirname (PG_FUNCTION_ARGS)
{
  char *dirc, *dname;
  text *path;
  text *result;

  if (PG_ARGISNULL (0))
    {
      PG_RETURN_NULL ();
    }

  path = PG_GETARG_TEXT_P (0);
  dirc = (char *) palloc (VARSIZE (path) - VARHDRSZ + 1);
  memcpy (dirc, VARDATA (path), VARSIZE (path) - VARHDRSZ);
  *(dirc + VARSIZE (path) - VARHDRSZ) = '\0';
  dname = dirname (dirc);

  result = (text *) palloc (VARHDRSZ + strlen (dname));
  SET_VARSIZE (result, VARHDRSZ + strlen (dname));
  memcpy (VARDATA (result), dname, strlen (dname));

  PG_RETURN_TEXT_P (result);
}

PG_FUNCTION_INFO_V1 (pgbasename);

Datum
pgbasename (PG_FUNCTION_ARGS)
{
  char *dirc, *dbase;
  text *path;
  text *result;

  if (PG_ARGISNULL (0))
    {
      PG_RETURN_NULL ();
    }

  path = PG_GETARG_TEXT_P (0);
  dirc = (char *) palloc (VARSIZE (path) - VARHDRSZ + 1);
  memcpy (dirc, VARDATA (path), VARSIZE (path) - VARHDRSZ);
  *(dirc + VARSIZE (path) - VARHDRSZ) = '\0';
  dbase = basename (dirc);

  result = (text *) palloc (VARHDRSZ + strlen (dbase));
  SET_VARSIZE (result, VARHDRSZ + strlen (dbase));
  memcpy (VARDATA (result), dbase, strlen (dbase));

  PG_RETURN_TEXT_P (result);
}
