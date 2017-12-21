#include the runner
TESTDB=doxxy
dropdb $TESTDB
createdb $TESTDB
psql $TESTDB < build.sql --quiet
echo "Testing the save functionality"

psql $TESTDB < tests/save.sql
