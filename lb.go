package golb

import (
	"net/http"
	"net/url"
)

type LoadBalancer interface {
	NextServer() *url.URL
	Handler(w http.ResponseWriter, r *http.Request)
}

