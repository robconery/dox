BUILD=${CURDIR}/build.sql
FUNCTIONS=$(shell ls scripts/functions/*.sql)
INIT=${CURDIR}/scripts/init.sql
TESTS=$(shell ls test/*.sql)
TEST=${CURDIR}/test.sql

all: init functions

exec: build
	psql dvdrental < $(BUILD)

init:
	@cat $(INIT) >> $(BUILD)

functions:
	@cat $(FUNCTIONS) >> $(BUILD)

test: 
	$(shell . ./test.sh)

clean:
	@rm -rf $(BUILD)

.PHONY: test