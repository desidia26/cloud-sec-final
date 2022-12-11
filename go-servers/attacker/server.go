package main

import (
		"os"
		"fmt"
		"net/http"
		"io/ioutil"
		"time"
)

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
			return value
	}
	return fallback
}

func main() {
	victim := getEnv("VICTIM_URL", "localhost:8080")
	fmt.Println("VICTIM: ", victim)
	for range time.Tick(time.Second * 5) {
		attack(victim, "notarealusername")
	}
}

func attack(URL string, username string) {
	fmt.Println("Sending req")
	response, err := http.Get(fmt.Sprintf("http://%s/login?username=%s&password=notarealpw", URL, username))
	fmt.Println("Resp received")

	if err != nil {
		fmt.Print(err.Error())
	} else {
		responseData, _ := ioutil.ReadAll(response.Body)
		fmt.Println(string(responseData))
	}
}
