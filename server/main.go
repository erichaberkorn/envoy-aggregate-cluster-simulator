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
	priority := os.Getenv("PRIORITY")
	port, err := strconv.Atoi(portStr)
	if err != nil {
		log.Fatal(err)
	}

	http.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		if success {
			io.WriteString(w, fmt.Sprintf("%s - %s - %s - success\n", clusterName, priority, portStr))
		} else {
			w.WriteHeader(http.StatusInternalServerError)

			io.WriteString(w, fmt.Sprintf("%s - %s - %s - fail\n", clusterName, priority, portStr))
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
