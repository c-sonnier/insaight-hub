package client

import "encoding/json"

type Organization struct {
	ID   string `json:"id"`
	Name string `json:"name"`
	Role string `json:"role"`
}

func (c *Client) ListOrganizations() ([]Organization, error) {
	body, err := c.Get("/api/v1/organizations")
	if err != nil {
		return nil, err
	}
	var resp struct {
		Organizations []Organization `json:"organizations"`
	}
	if err := json.Unmarshal(body, &resp); err != nil {
		return nil, err
	}
	return resp.Organizations, nil
}
