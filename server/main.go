package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
)

func main() {
	success := true
	clusterName := os.Getenv("CLUSTER_NAME")
	portStr := os.Getenv("SERVER_PORT")
	port, err := strconv.Atoi(portStr)
	if err != nil {
		log.Fatal(err)
	}

	http.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		if success {
			io.WriteString(w, fmt.Sprintf("%s - success\n", clusterName))
		} else {
			w.WriteHeader(http.StatusInternalServerError)

			io.WriteString(w, fmt.Sprintf("%s - fail\n", clusterName))
		}
	})

	http.HandleFunc("/status", func(w http.ResponseWriter, r *http.Request) {
		value := r.URL.Query().Get("value")

		if value == "fail" {
			success = false
		}

		io.WriteString(w, "updated status\n")
	})

	err = http.ListenAndServe(fmt.Sprintf(":%d", port), nil)

	if err != nil {
		log.Fatal(err)
	}
}
