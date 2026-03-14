package main

import (
	"flag"
	"fmt"
	"net/http"

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

func main () {
	port := flag.Int("port",8001, "Port to start the server on")
	flag.Parse()
	StartServer(*port)
	select{}
}