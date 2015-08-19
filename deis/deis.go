package deis

import (
	"github.com/gliderlabs/logspout/router"
)

func init() {
	router.AdapterTransports.Register(new(deisTransport), "deis-udp")
	router.AdapterFactories.Register(NewDeisLogAdapter, "deis")
	router.Jobs.Register(NewDeisConfigJob(), "deis-config-job")
}
