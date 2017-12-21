#include the runner
TESTDB=dox_tests
psql -c "drop database if exists $TESTDB;" --quiet
psql -c "create database $TESTDB;" --quiet
psql $TESTDB < build.sql --quiet
echo "Here we go!"

psql $TESTDB < tests/save.sql
psql $TESTDB < tests/finding.sql
psql $TESTDB < tests/starts_with.sql
psql $TESTDB < tests/modify.sql
