NAME=logspout-deis-dev
TEST_LOG_SERVER_PATH=tests/fixtures/test-log-server
TEST_ETCD_PATH=tests/fixtures/test-etcd

clean-test-log-server:
	@docker rmi log-server:test &> /dev/null

start-test-log-server:
	@docker history log-server:test &> /dev/null || docker build -f $(TEST_LOG_SERVER_PATH)/Dockerfile -t log-server:test $(TEST_LOG_SERVER_PATH)
	@docker run --name test-log-server -d --net=host log-server:test &> /dev/null
	@echo "test-log-server container is started."

stop-test-log-server:
	@docker kill test-log-server &> /dev/null
	@docker rm test-log-server &> /dev/null
	@echo "test-log-server container is stopped."

clean-test-etcd:
	@docker rmi etcd:test &> /dev/null

start-test-etcd:
	@docker history etcd:test &> /dev/null || docker build -f $(TEST_ETCD_PATH)/Dockerfile -t etcd:test $(TEST_ETCD_PATH)
	@docker run --name test-etcd -d --net=host etcd:test &> /dev/null
	@sleep 5
	@docker exec test-etcd etcdctl set /deis/logs/host 127.0.0.1 &> /dev/null
	@docker exec test-etcd etcdctl set /deis/logs/port 514 &> /dev/null
	@echo "test-etcd container is started."

stop-test-etcd:
	@docker kill test-etcd &> /dev/null
	@docker rm test-etcd &> /dev/null
	@echo "test-etcd container is stopped."

dev-clean:
	@docker rmi $(NAME):dev &> /dev/null

dev-build:
	@go build deis/*.go && docker build -t $(NAME):dev .

dev-run:
	@docker run --rm -e ETCD_HOST=127.0.0.1 -e ETCD_PORT=2379 -e DEBUG=true --net=host -v /var/run/docker.sock:/var/run/docker.sock $(NAME):dev