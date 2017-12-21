#include the runner
TESTDB=doxxy
dropdb $TESTDB
createdb $TESTDB
psql $TESTDB < build.sql --quiet
echo "Here we go!"

psql $TESTDB < tests/save.sql
psql $TESTDB < tests/finding.sql
