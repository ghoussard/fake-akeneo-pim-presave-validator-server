package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

type logEntry struct {
	Timestamp string `json:"timestamp"`
	Type      string `json:"type"`
}

type productErrors struct {
	Errors []any `json:"errors"`
}

type response struct {
	Products []productErrors `json:"products"`
}

func handler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
		return
	}

	var body map[string]json.RawMessage
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	}

	var productCount int
	requestType := "unitary"

	if raw, ok := body["products"]; ok {
		requestType = "batch"
		var products []json.RawMessage
		if err := json.Unmarshal(raw, &products); err != nil {
			http.Error(w, "Bad Request", http.StatusBadRequest)
			return
		}
		productCount = len(products)
	} else if _, ok := body["product"]; ok {
		productCount = 1
	} else {
		http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	}

	entry := logEntry{
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Type:      requestType,
	}
	json.NewEncoder(os.Stdout).Encode(entry)

	time.Sleep(250 * time.Millisecond)

	products := make([]productErrors, productCount)
	for i := range products {
		products[i] = productErrors{Errors: []any{}}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response{Products: products})
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		log.Fatal("PORT environment variable is required")
	}

	http.HandleFunc("/", handler)
	log.Printf("Listening on port %s", port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%s", port), nil))
}
