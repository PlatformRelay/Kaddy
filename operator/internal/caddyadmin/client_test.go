/*
Copyright 2026.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package caddyadmin_test

import (
	"context"
	"errors"
	"net/http"
	"testing"
	"time"

	"github.com/PlatformRelay/Kaddy/operator/internal/caddyadmin"
	"github.com/PlatformRelay/Kaddy/operator/internal/caddyadmin/admintest"
)

const routesPath = "/config/apps/http/servers/srv0/routes"

func testRoute(id string) caddyadmin.Route {
	return caddyadmin.Route{
		ID: id,
		Body: map[string]any{
			"match":  []any{map[string]any{"host": []any{"demo.example.com"}}},
			"handle": []any{map[string]any{"handler": "reverse_proxy"}},
		},
	}
}

func ctxWithTimeout(t *testing.T) context.Context {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	t.Cleanup(cancel)
	return ctx
}

func TestClient_Ping(t *testing.T) {
	srv := admintest.NewServer()
	t.Cleanup(srv.Close)

	c := caddyadmin.New(srv.URL())
	if err := c.Ping(ctxWithTimeout(t)); err != nil {
		t.Fatalf("Ping against healthy admin API: %v", err)
	}
}

func TestClient_Ping_Unavailable(t *testing.T) {
	srv := admintest.NewServer()
	t.Cleanup(srv.Close)
	srv.SetUnavailable(true)

	c := caddyadmin.New(srv.URL())
	err := c.Ping(ctxWithTimeout(t))
	if !errors.Is(err, caddyadmin.ErrUnavailable) {
		t.Fatalf("Ping against 503 admin API: want ErrUnavailable, got %v", err)
	}
}

func TestClient_Ping_ConnectionRefused(t *testing.T) {
	c := caddyadmin.New("http://127.0.0.1:1") // nothing listens here
	err := c.Ping(ctxWithTimeout(t))
	if !errors.Is(err, caddyadmin.ErrUnavailable) {
		t.Fatalf("Ping against dead endpoint: want ErrUnavailable, got %v", err)
	}
}

// REQ-E9-S02-02 (client half): upserting the same @id repeatedly must create
// the route exactly once (single POST) and strictly replace it via PATCH
// afterwards. Real Caddy admin API semantics: POST appends to arrays and PUT
// *inserts* — both pile up duplicate routes, so neither may ever hit an
// existing @id.
func TestClient_UpsertRoute_Idempotent(t *testing.T) {
	const wantID = "kaddy.default.clubhouse"

	srv := admintest.NewServer()
	t.Cleanup(srv.Close)

	c := caddyadmin.New(srv.URL())
	route := testRoute(wantID)

	for i := range 3 {
		if err := c.UpsertRoute(ctxWithTimeout(t), routesPath, route); err != nil {
			t.Fatalf("UpsertRoute #%d: %v", i+1, err)
		}
	}

	if got := srv.RouteCount(); got != 1 {
		t.Fatalf("route count after 3 upserts: want 1, got %d (duplicates piled up)", got)
	}

	posts, patches := 0, 0
	for _, r := range srv.Requests() {
		switch r.Method {
		case http.MethodPost:
			posts++
		case http.MethodPut:
			t.Fatalf("PUT %s observed: PUT inserts in the Caddy admin API and must never be used for upserts", r.Path)
		case http.MethodPatch:
			patches++
			if r.Path != "/id/"+wantID {
				t.Fatalf("PATCH to unexpected path %s", r.Path)
			}
		}
	}
	if posts != 1 {
		t.Fatalf("POST count: want exactly 1 create, got %d", posts)
	}
	if patches < 2 {
		t.Fatalf("PATCH count: want >=2 strict replaces, got %d", patches)
	}

	stored, ok := srv.Route(wantID)
	if !ok {
		t.Fatal("route not stored under its @id")
	}
	if stored["@id"] != wantID {
		t.Fatalf("stored route @id: want %s, got %v", wantID, stored["@id"])
	}
}

func TestClient_UpsertRoute_Unavailable(t *testing.T) {
	srv := admintest.NewServer()
	t.Cleanup(srv.Close)
	srv.SetUnavailable(true)

	c := caddyadmin.New(srv.URL())
	err := c.UpsertRoute(ctxWithTimeout(t), routesPath, testRoute("x"))
	if !errors.Is(err, caddyadmin.ErrUnavailable) {
		t.Fatalf("UpsertRoute against 503: want ErrUnavailable, got %v", err)
	}
}

func TestClient_DeleteRoute(t *testing.T) {
	srv := admintest.NewServer()
	t.Cleanup(srv.Close)

	c := caddyadmin.New(srv.URL())
	if err := c.UpsertRoute(ctxWithTimeout(t), routesPath, testRoute("gone")); err != nil {
		t.Fatalf("UpsertRoute: %v", err)
	}
	if err := c.DeleteRoute(ctxWithTimeout(t), "gone"); err != nil {
		t.Fatalf("DeleteRoute: %v", err)
	}
	if got := srv.RouteCount(); got != 0 {
		t.Fatalf("route count after delete: want 0, got %d", got)
	}
	// deleting an unknown id is a no-op, not an error
	if err := c.DeleteRoute(ctxWithTimeout(t), "gone"); err != nil {
		t.Fatalf("DeleteRoute of unknown id must be a no-op, got %v", err)
	}
}
