NAME=logspout-deis-dev
TEST_ETCD_IMAGE=quay.io/coreos/etcd:v2.1.2
# TEST_LOG_SERVER_IMAGE=deis/logger:v1.9.0
TEST_LOG_SERVER_IMAGE=krancour/deis-logger:underscores

start-test-etcd:
	@docker history $(TEST_ETCD_IMAGE) &> /dev/null || docker pull $(TEST_ETCD_IMAGE) &> /dev/null
	@docker run --name test-etcd -d --net=host $(TEST_ETCD_IMAGE) &> /dev/null
	@echo "test-etcd container is started."

stop-test-etcd:
	@docker kill test-etcd &> /dev/null
	@docker rm test-etcd &> /dev/null
	@echo "test-etcd container is stopped."

run-test-log-server:
	@docker history $(TEST_LOG_SERVER_IMAGE) &> /dev/null || docker pull $(TEST_LOG_SERVER_IMAGE) &> /dev/null
	@docker run --name deis-logger --rm --net=host -e EXTERNAL_PORT=514 -e HOST=127.0.0.1 -e LOGSPOUT=ignore -v /var/lib/deis/store:/data $(TEST_LOG_SERVER_IMAGE)

dev-clean:
	@docker rmi $(NAME):dev &> /dev/null || true

dev-build:
# Build go code BEFORE trying to build the container-- the point is to fail fast
	@go build deis/*.go && docker build -t $(NAME):dev .

dev-run:
	@docker run --name logspout-dev --rm -e ETCD_HOST=127.0.0.1 -e ETCD_PORT=2379 -e DEBUG=true -e LOGSPOUT=ignore --net=host -v /var/run/docker.sock:/var/run/docker.sock $(NAME):dev

test-style:
# Run gofmt first to display its output
	gofmt -l deis
# Run it again and assess whether it failed; if so, exit
	@gofmt -l deis | read; if [ $$? == 0 ]; then echo "gofmt check failed."; exit 1; fi

test: test-style

commit-hook:
	cp contrib/util/commit-msg .git/hooks/commit-msg

