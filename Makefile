NAME=logspout-deis-dev
TEST_ETCD_VERSION=v2.1.2
TEST_LOG_SERVER_VERSION=v1.9.0

start-test-etcd:
	@docker history quay.io/coreos/etcd:$(TEST_ETCD_VERSION) &> /dev/null || docker pull quay.io/coreos/etcd:$(TEST_ETCD_VERSION) &> /dev/null
	@docker run --name test-etcd -d --net=host quay.io/coreos/etcd:$(TEST_ETCD_VERSION) &> /dev/null
	@echo "test-etcd container is started."

stop-test-etcd:
	@docker kill test-etcd &> /dev/null
	@docker rm test-etcd &> /dev/null
	@echo "test-etcd container is stopped."

run-test-log-server:
	@docker history deis/logger:$(TEST_LOG_SERVER_VERSION) &> /dev/null || docker pull deis/logger:$(TEST_LOG_SERVER_VERSION) &> /dev/null
	@docker run --name deis-logger --rm --net=host -e EXTERNAL_PORT=514 -e HOST=127.0.0.1 -v /var/lib/deis/store:/data deis/logger:$(TEST_LOG_SERVER_VERSION)

dev-clean:
	@docker rmi $(NAME):dev &> /dev/null || true

dev-build:
	@go build deis/*.go && docker build -t $(NAME):dev .

dev-run:
	@docker run --rm -e ETCD_HOST=127.0.0.1 -e ETCD_PORT=2379 -e DEBUG=true --net=host -v /var/run/docker.sock:/var/run/docker.sock $(NAME):dev