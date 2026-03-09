package roundrobin

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"sync"
	"testing"
	"time"
)

type MockServer struct {
	server       *httptest.Server
	requestCount int
	mutex        sync.Mutex
}

func NewMockServer(id int) *MockServer {
	ms := &MockServer{}
	ms.server = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ms.mutex.Lock()
		ms.requestCount++
		count := ms.requestCount
		ms.mutex.Unlock()

		time.Sleep(10 * time.Millisecond)
		fmt.Fprintf(w, "Server %d - request %d", id, count)
	}))
	return ms
}

func (ms *MockServer) GetRequestCount() int {
	ms.mutex.Lock()
	defer ms.mutex.Unlock()
	return ms.requestCount
}

func (ms *MockServer) Close() {
	ms.server.Close()
}

func (ms *MockServer) URL() *url.URL {
	url, _ := url.Parse(ms.server.URL)
	return url
}

func TestRoundRobin(t *testing.T) {
	servers := make([]*MockServer, 5)
	urls := make([]*url.URL, 5)

	for i := range 5 {
		servers[i] = NewMockServer(i)
		urls[i] = servers[i].URL()
		defer servers[i].Close()
	}

	lb := NewRoundRobin(urls)

	serverHits := make(map[string]int)

	for range 50 {
		server := lb.NextServer()
		if server != nil {
			serverHits[server.String()]++
		}
	}

	for serverURL, hits := range serverHits {
		if hits != 10 {
			t.Errorf("Round Robin failed: Server %s got %d requests, expected 10", serverURL, hits)
		}
	}
	t.Logf("Round Robin test passed. Distribution: %v", serverHits)
}
