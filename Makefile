DB=CHANGE_ME
BUILD=${CURDIR}/build.sql
FUNCTIONS=$(shell ls scripts/functions/*.sql)
INIT=${CURDIR}/scripts/init.sql
TESTS=$(shell ls test/*.sql)
TEST=${CURDIR}/test.sql

all: init functions

install: all
	@psql $(DB) < $(BUILD) --quiet

init:
	@cat $(INIT) >> $(BUILD)

functions:
	@cat $(FUNCTIONS) >> $(BUILD)

test: clean install
	. ./test.sh

clean:
	@rm -rf $(BUILD)

.PHONY: test