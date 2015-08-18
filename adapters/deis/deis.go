package deis

import (
	"errors"
	"fmt"
	"log"
	"net"
	"os"
	"reflect"
	"regexp"
	"time"

	"github.com/coreos/go-etcd/etcd"
	dtime "github.com/deis/deis/pkg/time"
	"github.com/gliderlabs/logspout/router"
)

func init() {
	router.AdapterFactories.Register(NewDeisLogAdapter, "deis")

	// If we are connecting to etcd, get the logger's connection
	// details from there.
	// TODO: We should really start a job that will modify the route
	// if this changes.
	if etcdHost := os.Getenv("ETCD_HOST"); etcdHost != "" {
		connectionString := []string{"http://" + etcdHost + ":4001"}
		log.Println("etcd: " + connectionString[0])
		etcd := etcd.NewClient(connectionString)
		etcd.SetDialTimeout(3 * time.Second)
		hostResp, err := etcd.Get("/deis/logs/host", false, false)
		if err != nil {
			log.Fatal("etcd:", err)
		}
		portResp, err := etcd.Get("/deis/logs/port", false, false)
		if err != nil {
			log.Fatal("etcd:", err)
		}
		host := fmt.Sprintf("%s:%s", hostResp.Node.Value, portResp.Node.Value)
		if err := router.Routes.Add(&router.Route{Address: host, Adapter: "deis", Options: make(map[string]string)}); err != nil {
			log.Println("deis:", err)
		}
	}
}

type DeisLogAdapter struct {
	conn  net.Conn
	route *router.Route
}

func NewDeisLogAdapter(route *router.Route) (router.LogAdapter, error) {
	transport, found := router.AdapterTransports.Lookup(route.AdapterTransport("udp"))
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
