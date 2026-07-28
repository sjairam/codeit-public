package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func printUsage(prog string) {
	fmt.Printf(`Usage: %s [-p profile] [-r region] [-h]

Options:
  -p profile   AWS CLI profile to use (optional)
  -r region    AWS region to use (optional)
  -h           Show this help message

What it does:
  - Calls: aws elbv2 describe-load-balancers
  - Filters to Type == "application"
  - Prints a table of ALB Name and ARN
  - Prints the total count of Application Load Balancers
`, prog)
}

func resolveRegion(awsPath, profileArg, regionArg string) string {
	if regionArg != "" {
		return regionArg
	}

	args := []string{"configure", "get", "region"}
	if profileArg != "" {
		args = append(args, "--profile", profileArg)
	}
	cmd := exec.Command(awsPath, args...)
	var out bytes.Buffer
	cmd.Stdout = &out
	if err := cmd.Run(); err == nil {
		if region := strings.TrimSpace(out.String()); region != "" {
			return region
		}
	}

	if region := os.Getenv("AWS_REGION"); region != "" {
		return region
	}
	if region := os.Getenv("AWS_DEFAULT_REGION"); region != "" {
		return region
	}

	return "unknown"
}

func main() {
	prog := filepath.Base(os.Args[0])

	awsPath, err := exec.LookPath("aws")
	if err != nil {
		fmt.Println("ERROR: The aws binary does not exist or is not executable.")
		fmt.Println("FIX: Please install AWS CLI and ensure it is in your PATH.")
		os.Exit(1)
	}

	// Parse simple flags: -p profile, -r region, -h
	var profileArg, regionArg string

	args := os.Args[1:]
	for i := 0; i < len(args); i++ {
		arg := args[i]
		switch arg {
		case "-h", "--help":
			printUsage(prog)
			return
		case "-p", "--profile":
			if i+1 >= len(args) {
				fmt.Println("ERROR: -p/--profile requires a value.")
				fmt.Println()
				printUsage(prog)
				os.Exit(1)
			}
			i++
			profileArg = args[i]
		case "-r", "--region":
			if i+1 >= len(args) {
				fmt.Println("ERROR: -r/--region requires a value.")
				fmt.Println()
				printUsage(prog)
				os.Exit(1)
			}
			i++
			regionArg = args[i]
		default:
			fmt.Printf("ERROR: Unknown argument: %s\n\n", arg)
			printUsage(prog)
			os.Exit(1)
		}
	}

	region := resolveRegion(awsPath, profileArg, regionArg)
	fmt.Printf("AWS Region: %s\n\n", region)

	var baseArgs []string
	baseArgs = append(baseArgs,
		"elbv2", "describe-load-balancers",
		"--query", "LoadBalancers[?Type=='application'].{Name:LoadBalancerName, ARN:LoadBalancerArn}",
		"--output", "table",
	)

	// Add profile / region if provided
	if profileArg != "" {
		baseArgs = append(baseArgs, "--profile", profileArg)
	}
	if regionArg != "" {
		baseArgs = append(baseArgs, "--region", regionArg)
	}

	fmt.Println("Fetching Application Load Balancers...")

	// First command: fetch ALBs as a table
	cmd := exec.Command(awsPath, baseArgs...)

	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = os.Stderr

	err = cmd.Run()
	if err != nil {
		fmt.Printf("ERROR: Failed to fetch load balancers: %v\n", err)
		fmt.Println("HINT: Check your AWS credentials, region, and permissions.")
		os.Exit(2)
	}

	loadBalancers := strings.TrimSpace(out.String())

	// Second command: get the count of ALBs
	countArgs := []string{
		"elbv2", "describe-load-balancers",
		"--query", "length(LoadBalancers[?Type=='application'])",
		"--output", "text",
	}
	if profileArg != "" {
		countArgs = append(countArgs, "--profile", profileArg)
	}
	if regionArg != "" {
		countArgs = append(countArgs, "--region", regionArg)
	}

	var countOut bytes.Buffer
	countCmd := exec.Command(awsPath, countArgs...)
	countCmd.Stdout = &countOut
	countCmd.Stderr = os.Stderr

	if err := countCmd.Run(); err != nil {
		fmt.Printf("WARNING: Failed to fetch ALB count: %v\n", err)
	}

	albCount := strings.TrimSpace(countOut.String())

	// Check if there are any ALBs found
	if loadBalancers == "" || strings.Contains(loadBalancers, "No Load Balancers found") {
		fmt.Println("No Application Load Balancers found.")
	} else {
		fmt.Println()
		fmt.Println("Application Load Balancers:")
		fmt.Println(loadBalancers)

		if albCount != "" && albCount != "None" {
			fmt.Printf("\nTotal Application Load Balancers: %s\n", albCount)
		}
	}
}
