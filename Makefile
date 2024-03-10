.PHONY: test
test:
	forge test --gas-report

.PHONY: test_watch
test_watch:
	forge test --gas-report --watch

.PHONY: test_debug
test_debug:
	forge test --gas-report -vvvvv --watch

.PHONY: examine_storage
examine_storage:
	sol2uml storage -c GasContract src

.PHONY: examine_class
examine_class:
	sol2uml src

.PHONY: before_commit
before_commit: test examine_storage examine_class
