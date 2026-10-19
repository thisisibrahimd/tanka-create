TEST_ARGS ?= -count=1

.PHONY: init
init:
	cd default && jb install

.PHONY: test
test: init
	go test $(TEST_ARGS) ./... 
