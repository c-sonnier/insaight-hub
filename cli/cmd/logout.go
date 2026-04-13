package cmd

import (
	"fmt"

	"github.com/c-sonnier/insaight-hub/cli/internal/config"
	"github.com/spf13/cobra"
)

var logoutCmd = &cobra.Command{
	Use:   "logout",
	Short: "Remove the API token from the config file",
	RunE: func(cmd *cobra.Command, _ []string) error {
		cfg, err := config.LoadFrom(config.DefaultPath())
		if err != nil {
			return err
		}
		cfg.Token = ""
		if err := config.Save(cfg); err != nil {
			return err
		}
		fmt.Fprintf(cmd.OutOrStdout(), "Cleared token in %s\n", config.DefaultPath())
		return nil
	},
}
