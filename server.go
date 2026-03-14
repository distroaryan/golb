package golb

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/distroaryan/golb/logger"
)

func StartServer(port int) {
	addr := fmt.Sprintf(":%d", port)
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	go func() {
		if logger.Log != nil {
			logger.Log.Info("Server started", "port", port)
		}
		err := http.ListenAndServe(addr, mux)
		if err != nil && logger.Log != nil {
			logger.Log.Error("Server shutdown or failed", "port", port, "error", err)
		}
	}()
}

func StopServer(server *http.Server) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5 * time.Second)
	defer cancel()
	return server.Shutdown(ctx)
}