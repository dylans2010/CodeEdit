package main

import (
	"encoding/json"
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{
			"project": "{{PROJECT_NAME}}",
			"status":  "running",
		})
	})

	log.Println("Server listening on :8080...")
	log.Fatal(http.ListenAndServe(":8080", mux))
}
