package golb

import (
	"fmt"
	"log"
	"net/http"
)

func StartServer(port int) {
	addr := fmt.Sprintf(":%d", port)
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Printf("Server started on PORT: %d", port)
	})
	go func(){
		log.Printf("Server started on PORT: %d", port)
		log.Fatal(http.ListenAndServe(addr, mux))
	}()
}