package main

// Try Go with all databases
import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// Improved usage function with better formatting and examples
func usage() {
	fmt.Println("=" + strings.Repeat("=", 60))
	fmt.Println("                    RDS Instance Lister")
	fmt.Println("=" + strings.Repeat("=", 60))
	fmt.Println()
	fmt.Println("DESCRIPTION:")
	fmt.Println("  This program lists AWS RDS instances by database engine type.")
	fmt.Println("  It requires Go to be installed and AWS CLI to be configured.")
	fmt.Println()
	fmt.Println("USAGE:")
	fmt.Println("  go run list-rds.go <database-engine>")
	fmt.Println("  ./list-rds <database-engine>")
	fmt.Println()
	fmt.Println("ARGUMENTS:")
	fmt.Println("  database-engine    The type of database engine to list")
	fmt.Println("                     Valid options: mysql, postgres, oracle-ee")
	fmt.Println()
	fmt.Println("EXAMPLES:")
	fmt.Println("  go run list-rds.go postgres")
	fmt.Println("  go run list-rds.go mysql")
	fmt.Println("  go run list-rds.go oracle-ee")
	fmt.Println()
	fmt.Println("FLAGS:")
	fmt.Println("  -h, --help         Show this help message")
	fmt.Println()
	fmt.Println("PREREQUISITES:")
	fmt.Println("  - Go must be installed and in PATH")
	fmt.Println("  - AWS CLI must be installed and configured")
	fmt.Println("  - AWS credentials must have RDS read permissions")
	fmt.Println()
	fmt.Println("OUTPUT:")
	fmt.Println("  Displays a table with the following columns:")
	fmt.Println("  - DBInstanceIdentifier")
	fmt.Println("  - DBInstanceClass")
	fmt.Println("  - Engine")
	fmt.Println("  - EngineVersion")
	fmt.Println("  - DBInstanceStatus")
	fmt.Println("  - AllocatedStorage")
	fmt.Println("  - MultiAZ")
	fmt.Println()
	fmt.Println("=" + strings.Repeat("=", 60))
	os.Exit(1)
}

func main() {
	// Check for help flag
	if len(os.Args) > 1 && (os.Args[1] == "--help" || os.Args[1] == "-h") {
		usage()
	}

	//Check if GO installed
	goPath, err := exec.LookPath("go")
	if err != nil {
		fmt.Println("ERROR: The Go binary does not exist or is not executable.")
		fmt.Println("Please install Go and ensure it is in your PATH.")
		os.Exit(1)
	}
	fmt.Printf("Go found at: %s\n", goPath)

	if len(os.Args) < 2 {
		usage()
	}

	engine := strings.ToLower(os.Args[1])
	validEngines := []string{"postgres", "mysql", "oracle-ee"}

	engineValid := false
	for _, validEngine := range validEngines {
		if engine == validEngine {
			engineValid = true
			break
		}
	}

	if !engineValid {
		fmt.Printf("ERROR: Invalid database engine '%s'\n", os.Args[1])
		fmt.Printf("Valid options are: %s\n", strings.Join(validEngines, ", "))
		fmt.Println()
		usage()
	}

	// Check if AWS CLI is installed
	awsPath, err := exec.LookPath("aws")
	if err != nil {
		fmt.Println("ERROR: The aws binary does not exist or is not executable.")
		fmt.Println("Please install AWS CLI and ensure it is in your PATH.")
		os.Exit(1)
	}

	// Prepare the command to fetch all RDS instances with specified database engine
	cmd := exec.Command(awsPath, "rds", "describe-db-instances",
		"--query", fmt.Sprintf("DBInstances[?Engine=='%s'].[DBInstanceIdentifier, DBInstanceClass, Engine, EngineVersion, DBInstanceStatus, AllocatedStorage, MultiAZ]", engine),
		"--output", "table")

	var out bytes.Buffer
	cmd.Stdout = &out

	cmd.Stderr = os.Stderr

	// Execute the command and capture its output
	err = cmd.Run()
	if err != nil {
		fmt.Printf("ERROR: %v\n", err)
		os.Exit(1)
	}

	rdsInstances := strings.TrimSpace(out.String())

	// Check if any RDS instances of specified engine are found
	if rdsInstances == "" {
		fmt.Printf("No %s RDS instances found in the current AWS region.\n", strings.Title(engine))
		fmt.Println("This could mean:")
		fmt.Println("  - No instances of this engine type exist")
		fmt.Println("  - AWS credentials don't have sufficient permissions")
		fmt.Println("  - You're in the wrong AWS region")
		fmt.Println("  - AWS CLI is not properly configured")
	} else {
		fmt.Printf("\n%s RDS Instances Found:\n", strings.Title(engine))
		fmt.Println(strings.Repeat("-", 80))
		fmt.Println(rdsInstances)
		fmt.Println(strings.Repeat("-", 80))
	}
}
