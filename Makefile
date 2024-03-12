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

.PHONY: open_class
open_class:
	open -a Google\ Chrome ./classDiagram.svg

.PHONY: open_storage
open_storage:
	open -a Google\ Chrome ./GasContract.svg

.PHONY: before_commit
before_commit: test examine_storage examine_class
