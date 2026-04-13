package cmd

import (
	"fmt"
	"strings"

	"github.com/c-sonnier/insaight-hub/cli/internal/client"
	"github.com/c-sonnier/insaight-hub/cli/internal/org"
	"github.com/c-sonnier/insaight-hub/cli/internal/output"
	"github.com/spf13/cobra"
)

var insightsCmd = &cobra.Command{
	Use:   "insights",
	Short: "Manage insights",
}

var (
	insightsListStatus   string
	insightsListAudience string
	insightsListTag      string
	insightsListSearch   string
	insightsListPage     int
	insightsListPerPage  int
)

var insightsListCmd = &cobra.Command{
	Use:   "list",
	Short: "List insights in an organization",
	RunE: func(cmd *cobra.Command, _ []string) error {
		cfg, err := loadConfig()
		if err != nil {
			return err
		}
		c := client.New(cfg.URL, cfg.Token)
		orgID, err := org.Resolve(c, flagOrg, cfg.DefaultOrg)
		if err != nil {
			return err
		}

		items, pagination, err := c.ListInsights(orgID, client.ListInsightsOptions{
			Status:   insightsListStatus,
			Audience: insightsListAudience,
			Tag:      insightsListTag,
			Search:   insightsListSearch,
			Page:     insightsListPage,
			PerPage:  insightsListPerPage,
		})
		if err != nil {
			return err
		}

		return output.Render(map[string]any{
			"insight_items": items,
			"pagination":    pagination,
		}, outputMode())
	},
}

var insightsGetFormat string

var insightsGetCmd = &cobra.Command{
	Use:   "get <slug>",
	Short: "Fetch a single insight by slug (markdown by default)",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		cfg, err := loadConfig()
		if err != nil {
			return err
		}
		c := client.New(cfg.URL, cfg.Token)
		orgID, err := org.Resolve(c, flagOrg, cfg.DefaultOrg)
		if err != nil {
			return err
		}

		detail, err := c.GetInsight(orgID, args[0], insightsGetFormat)
		if err != nil {
			return err
		}

		if flagJSON {
			return output.Render(detail, output.ModeJSON)
		}
		return printInsightContent(cmd, detail)
	},
}

func printInsightContent(cmd *cobra.Command, detail *client.InsightDetail) error {
	var parts []string
	for _, f := range detail.Files {
		parts = append(parts, f.Content)
	}
	fmt.Fprintln(cmd.OutOrStdout(), strings.Join(parts, "\n\n"))
	return nil
}

func init() {
	insightsListCmd.Flags().StringVar(&insightsListStatus, "status", "", "filter by status (draft|published)")
	insightsListCmd.Flags().StringVar(&insightsListAudience, "audience", "", "filter by audience")
	insightsListCmd.Flags().StringVar(&insightsListTag, "tag", "", "filter by tag")
	insightsListCmd.Flags().StringVar(&insightsListSearch, "search", "", "full-text search query")
	insightsListCmd.Flags().IntVar(&insightsListPage, "page", 0, "page number")
	insightsListCmd.Flags().IntVar(&insightsListPerPage, "per-page", 0, "results per page (default 20)")

	insightsGetCmd.Flags().StringVar(&insightsGetFormat, "format", "markdown", "content format: markdown|html")

	insightsCmd.AddCommand(insightsListCmd, insightsGetCmd)
}
