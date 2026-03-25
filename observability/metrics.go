package observability

import (
	"net/http"
	"strconv"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	RequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "golb_requests_total",
			Help: "Total number of HTTP requests processed by the load balancer",
		},
		[]string{"method", "status", "backend"},
	)

	RequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "golb_request_duration_seconds",
			Help:    "Latency of HTTP requests in seconds",
			Buckets: []float64{0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10},
		},
		[]string{"method", "status", "backend"},
	)

)

type ResponseWriterRecorder struct {
	http.ResponseWriter
	StatusCode int
}

func (rw *ResponseWriterRecorder) WriteHeader(code int) {
	rw.StatusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// RecordMetrics records metrics for a given proxy request
func RecordMetrics(backend string, method string, start time.Time, statusCode int) {
	duration := time.Since(start).Seconds()
	statusStr := strconv.Itoa(statusCode)
	
	RequestsTotal.WithLabelValues(method, statusStr, backend).Inc()
	RequestDuration.WithLabelValues(method, statusStr, backend).Observe(duration)
}
