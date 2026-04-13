package main

import (
	"os"

	"github.com/c-sonnier/insaight-hub/cli/cmd"
)

func main() {
	if err := cmd.Execute(); err != nil {
		os.Exit(1)
	}
}
