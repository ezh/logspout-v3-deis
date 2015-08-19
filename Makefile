NAME=logspout-deis-dev
TEST_LOG_SERVER_VERSION=v1.9.0
TEST_ETCD_PATH=tests/fixtures/test-etcd

clean-test-etcd:
	@docker rmi etcd:test &> /dev/null

start-test-etcd:
	@docker history etcd:test &> /dev/null || docker build -f $(TEST_ETCD_PATH)/Dockerfile -t etcd:test $(TEST_ETCD_PATH)
	@docker run --name test-etcd -d --net=host etcd:test &> /dev/null
	@echo "test-etcd container is started."

stop-test-etcd:
	@docker kill test-etcd &> /dev/null
	@docker rm test-etcd &> /dev/null
	@echo "test-etcd container is stopped."

run-test-log-server:
	@docker history deis/logger:$(TEST_LOG_SERVER_VERSION) &> /dev/null || docker pull deis/logger:$(TEST_LOG_SERVER_VERSION) &> /dev/null
	@docker run --name deis-logger --rm --net=host -e EXTERNAL_PORT=514 -e HOST=127.0.0.1 -v /var/lib/deis/store:/data deis/logger:$(TEST_LOG_SERVER_VERSION)

dev-clean:
	@docker rmi $(NAME):dev &> /dev/null

dev-build:
	@go build deis/*.go && docker build -t $(NAME):dev .

dev-run:
	@docker run --rm -e ETCD_HOST=127.0.0.1 -e ETCD_PORT=2379 -e DEBUG=true --net=host -v /var/run/docker.sock:/var/run/docker.sock $(NAME):dev