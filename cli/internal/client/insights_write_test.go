package client

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/c-sonnier/insaight-hub/cli/internal/fileinput"
)

func TestCreateInsight_SendsPOSTWithJSONBody(t *testing.T) {
	var (
		method, path, auth, contentType string
		body                             map[string]any
	)

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		method = r.Method
		path = r.URL.Path
		auth = r.Header.Get("Authorization")
		contentType = r.Header.Get("Content-Type")
		raw, _ := io.ReadAll(r.Body)
		_ = json.Unmarshal(raw, &body)

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		w.Write([]byte(`{"id":1,"slug":"test-slug","title":"cli test","audience":"developer","status":"draft"}`))
	}))
	defer srv.Close()

	c := New(srv.URL, "tok")
	got, err := c.CreateInsight("org-uuid", CreateInsightReq{
		Title:    "cli test",
		Audience: "developer",
		Tags:     []string{"cli", "test"},
		Files: []fileinput.FileInput{
			{Filename: "index.html", Content: "<h1>hi</h1>", ContentType: "text/html"},
		},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.Slug != "test-slug" {
		t.Errorf("slug: got %q, want test-slug", got.Slug)
	}
	if method != "POST" {
		t.Errorf("method: got %q", method)
	}
	if path != "/org-uuid/api/v1/insight_items" {
		t.Errorf("path: got %q", path)
	}
	if auth != "Bearer tok" {
		t.Errorf("auth: got %q", auth)
	}
	if contentType != "application/json" {
		t.Errorf("content-type: got %q", contentType)
	}
	if body["title"] != "cli test" {
		t.Errorf("body title: got %v", body["title"])
	}
	if body["audience"] != "developer" {
		t.Errorf("body audience: got %v", body["audience"])
	}
	files, _ := body["files"].([]any)
	if len(files) != 1 {
		t.Fatalf("expected 1 file, got %d", len(files))
	}
	file := files[0].(map[string]any)
	if file["filename"] != "index.html" || file["content"] != "<h1>hi</h1>" {
		t.Errorf("file: got %v", file)
	}
}

func TestCreateInsight_OmitsEmptyOptionalFields(t *testing.T) {
	var body map[string]any
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		raw, _ := io.ReadAll(r.Body)
		_ = json.Unmarshal(raw, &body)
		w.WriteHeader(http.StatusCreated)
		w.Write([]byte(`{"id":1,"slug":"s","title":"t","audience":"developer","status":"draft"}`))
	}))
	defer srv.Close()

	c := New(srv.URL, "tok")
	_, err := c.CreateInsight("org", CreateInsightReq{Title: "t", Audience: "developer"})
	if err != nil {
		t.Fatalf("unexpected: %v", err)
	}

	for _, key := range []string{"description", "entry_file", "tags", "files"} {
		if _, present := body[key]; present {
			t.Errorf("expected %q to be omitted, got %v", key, body[key])
		}
	}
}

func TestCreateInsight_PublishTriggersFollowupCall(t *testing.T) {
	var calls []string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls = append(calls, r.Method+" "+r.URL.Path)
		w.Header().Set("Content-Type", "application/json")
		if r.Method == "POST" && r.URL.Path == "/org/api/v1/insight_items" {
			w.WriteHeader(http.StatusCreated)
			w.Write([]byte(`{"id":1,"slug":"pub-slug","title":"t","audience":"developer","status":"draft"}`))
			return
		}
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"id":1,"slug":"pub-slug","status":"published"}`))
	}))
	defer srv.Close()

	c := New(srv.URL, "tok")
	got, err := c.CreateInsight("org", CreateInsightReq{Title: "t", Audience: "developer", Publish: true})
	if err != nil {
		t.Fatalf("unexpected: %v", err)
	}

	if len(calls) != 2 {
		t.Fatalf("expected 2 calls, got %d: %v", len(calls), calls)
	}
	if calls[1] != "POST /org/api/v1/insight_items/pub-slug/publish" {
		t.Errorf("second call: got %q", calls[1])
	}
	if got.Status != "published" {
		t.Errorf("status: got %q, want published", got.Status)
	}
}

func TestCreateInsight_ReturnsAPIErrorOn422(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnprocessableEntity)
		w.Write([]byte(`{"errors":["Title can't be blank"]}`))
	}))
	defer srv.Close()

	c := New(srv.URL, "tok")
	_, err := c.CreateInsight("org", CreateInsightReq{Audience: "developer"})
	if err == nil {
		t.Fatal("expected error, got nil")
	}
	apiErr, ok := err.(*APIError)
	if !ok {
		t.Fatalf("expected *APIError, got %T: %v", err, err)
	}
	if apiErr.Status != 422 {
		t.Errorf("status: %d", apiErr.Status)
	}
}

func TestUpdateInsight_SendsPATCHWithOnlySetFields(t *testing.T) {
	var method, path string
	var body map[string]any
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		method = r.Method
		path = r.URL.Path
		raw, _ := io.ReadAll(r.Body)
		_ = json.Unmarshal(raw, &body)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"id":1,"slug":"s","description":"new"}`))
	}))
	defer srv.Close()

	c := New(srv.URL, "tok")
	got, err := c.UpdateInsight("org", "s", UpdateInsightReq{Description: "new"})
	if err != nil {
		t.Fatalf("unexpected: %v", err)
	}
	if got.Slug != "s" {
		t.Errorf("slug: %q", got.Slug)
	}
	if method != "PATCH" {
		t.Errorf("method: %q", method)
	}
	if path != "/org/api/v1/insight_items/s" {
		t.Errorf("path: %q", path)
	}
	if body["description"] != "new" {
		t.Errorf("description: %v", body["description"])
	}
	for _, key := range []string{"title", "audience", "entry_file", "tags", "files"} {
		if _, present := body[key]; present {
			t.Errorf("expected %q omitted, got %v", key, body[key])
		}
	}
}

func TestDeleteInsight_SendsDELETEAcceptsNoContent(t *testing.T) {
	var method, path string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		method = r.Method
		path = r.URL.Path
		w.WriteHeader(http.StatusNoContent)
	}))
	defer srv.Close()

	c := New(srv.URL, "tok")
	if err := c.DeleteInsight("org", "s"); err != nil {
		t.Fatalf("unexpected: %v", err)
	}
	if method != "DELETE" {
		t.Errorf("method: %q", method)
	}
	if path != "/org/api/v1/insight_items/s" {
		t.Errorf("path: %q", path)
	}
}

func TestDeleteInsight_Returns404AsAPIError(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotFound)
		w.Write([]byte(`{"error":"Insight not found"}`))
	}))
	defer srv.Close()

	c := New(srv.URL, "tok")
	err := c.DeleteInsight("org", "missing")
	if err == nil {
		t.Fatal("expected error, got nil")
	}
	apiErr, ok := err.(*APIError)
	if !ok {
		t.Fatalf("expected *APIError, got %T", err)
	}
	if apiErr.Status != 404 {
		t.Errorf("status: %d", apiErr.Status)
	}
}
