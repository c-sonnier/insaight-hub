package cmd

import (
	"github.com/c-sonnier/insaight-hub/cli/internal/client"
	"github.com/c-sonnier/insaight-hub/cli/internal/output"
	"github.com/spf13/cobra"
)

var organizationsCmd = &cobra.Command{
	Use:     "organizations",
	Aliases: []string{"orgs"},
	Short:   "Manage organizations",
}

var organizationsListCmd = &cobra.Command{
	Use:   "list",
	Short: "List organizations the current identity belongs to",
	RunE: func(cmd *cobra.Command, _ []string) error {
		cfg, err := loadConfig()
		if err != nil {
			return err
		}
		c := client.New(cfg.URL, cfg.Token)
		orgs, err := c.ListOrganizations()
		if err != nil {
			return err
		}
		return output.Render(map[string]any{"organizations": orgs}, outputMode())
	},
}

func init() {
	organizationsCmd.AddCommand(organizationsListCmd)
}
