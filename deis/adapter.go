package deis

import (
	"errors"
	"fmt"
	"log"
	"net"
	"reflect"
	"regexp"
	"time"

	dtime "github.com/deis/deis/pkg/time"
	"github.com/gliderlabs/logspout/router"
)

type DeisLogAdapter struct {
	conn  net.Conn
	route *router.Route
}

func NewDeisLogAdapter(route *router.Route) (router.LogAdapter, error) {
	transport, found := router.AdapterTransports.Lookup(route.AdapterTransport("deis-udp"))
	if !found {
		return nil, errors.New("bad transport: " + route.Adapter)
	}
	conn, err := transport.Dial(route.Address, route.Options)
	if err != nil {
		return nil, err
	}
	return &DeisLogAdapter{
		route: route,
		conn:  conn,
	}, nil
}

func (a *DeisLogAdapter) Stream(logstream chan *router.Message) {
	for message := range logstream {
		m := &DeisLogMessage{message}
		_, err := a.conn.Write(m.Render())
		if err != nil {
			log.Println("deis:", err)
			if reflect.TypeOf(a.conn).String() != "*net.UDPConn" {
				return
			}
		}
	}
}

type DeisLogMessage struct {
	*router.Message
}

func (m *DeisLogMessage) Render() []byte {
	tag, pid := getLogName(m.Container.Name)
	return []byte(fmt.Sprintf("%s %s[%s]: %s", time.Now().Format(dtime.DeisDatetimeFormat), tag, pid, m.Data))
}

// getLogName returns a custom tag and PID for containers that
// match Deis' specific application name format. Otherwise,
// it returns the original name and 1 as the PID.
func getLogName(name string) (string, string) {
	// example regex that should match: go_v2.web.1
	match := getMatch(`(^[a-z0-9-]+)_(v[0-9]+)\.([a-z-_]+\.[0-9]+)$`, name)
	if match != nil {
		return match[1], match[3]
	}
	match = getMatch(`^k8s_([a-z0-9-]+)-([a-z]+)\.`, name)
	if match != nil {
		return match[1], match[2]
	}
	return name, "1"
}

func getMatch(regex string, name string) []string {
	r := regexp.MustCompile(regex)
	match := r.FindStringSubmatch(name)
	return match
}
