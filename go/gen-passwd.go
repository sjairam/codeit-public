package main

import (
	"fmt"
	"math/rand"
	"strings"
	"time"
)

func main() {

	letters := []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
	numbers := []rune("0123456789")
	symbols := []rune("!#$%&()*+")

	var nrLetters, nrSymbols, nrNumbers int

	fmt.Println("Welcome to the GoPassword Generator!")
	fmt.Print("How many letters would you like in your password?\n")
	fmt.Scan(&nrLetters)

	fmt.Print("How many symbols would you like?\n")
	fmt.Scan(&nrSymbols)

	fmt.Print("How many numbers would you like?\n")
	fmt.Scan(&nrNumbers)

	var passwordRunes []rune

	rand.Seed(time.Now().UnixNano())

	for i := 0; i < nrLetters; i++ {
		passwordRunes = append(passwordRunes, letters[rand.Intn(len(letters))])
	}

	for i := 0; i < nrSymbols; i++ {
		passwordRunes = append(passwordRunes, symbols[rand.Intn(len(symbols))])
	}

	for i := 0; i < nrNumbers; i++ {
		passwordRunes = append(passwordRunes, numbers[rand.Intn(len(numbers))])
	}

	// Shuffle the slice
	rand.Shuffle(len(passwordRunes), func(i, j int) {
		passwordRunes[i], passwordRunes[j] = passwordRunes[j], passwordRunes[i]
	})

	password := strings.Builder{}
	for _, char := range passwordRunes {
		password.WriteRune(char)
	}

	fmt.Printf("Your password is: %s\n", password.String())

}
