FROM gliderlabs/alpine:3.1
VOLUME /mnt/routes

RUN apk-install go git mercurial

ENV GOPATH /go

RUN git clone https://github.com/gliderlabs/logspout.git /go/src/github.com/gliderlabs/logspout
COPY deis /go/src/github.com/gliderlabs/logspout/deis
COPY modules.go /go/src/github.com/gliderlabs/logspout/modules.go

WORKDIR /go/src/github.com/gliderlabs/logspout
RUN go get
CMD go get \
	&& go build -ldflags "-X main.Version dev" -o /bin/logspout \
	&& exec /bin/logspout
