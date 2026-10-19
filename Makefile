TEST_ARGS ?= -count=1

.PHONY: test
test:
	go test $(TEST_ARGS) ./... 
