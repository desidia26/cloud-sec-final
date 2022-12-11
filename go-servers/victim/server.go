package main

import (
    "fmt"
    "log"
    "net/http"
		"strings"
)

func main() {
	creds := make(map[string]string)
	creds["foo"] = "bar"

	fmt.Printf("Starting server at port 8080\n")
	http.HandleFunc("/login", func(w http.ResponseWriter, r *http.Request){
		ip := strings.Split(r.RemoteAddr, ":")[0]
		username := r.URL.Query().Get("username")
		password := r.URL.Query().Get("password")
		if val, ok := creds[username]; ok {
			if (val == password) {
				fmt.Fprintf(w, fmt.Sprintf("Congratulations on logging in, %s!", username))
			} else {
				fmt.Println(fmt.Sprintf("Failed login attempt from ip: %s!", ip))
				fmt.Fprintf(w, fmt.Sprintf("Failed login attempt, %s!", username))
			}
		} else {
			fmt.Println(fmt.Sprintf("Failed login attempt from ip: %s!", ip))
			fmt.Fprintf(w, "User "+username+" does not exist!")
		}
	})

	http.HandleFunc("/addUser", func(w http.ResponseWriter, r *http.Request){
		username := r.URL.Query().Get("username")
		password := r.URL.Query().Get("password")
		creds[username] = password
		fmt.Fprintf(w, "User added!")
	})

	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}