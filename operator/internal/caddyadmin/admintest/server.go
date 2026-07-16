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

// Package admintest provides a fake Caddy admin API for unit and envtest
// suites, faithful to the real verb semantics (caddyserver.com/docs/api):
//
//   - POST to an array path (e.g. .../routes) APPENDS — even when a route
//     with the same `@id` already exists (duplicates are possible!)
//   - PUT creates a new value / INSERTS into arrays — it is NOT a replace;
//     PUT against an existing `@id` inserts a duplicate next to it
//   - PATCH strictly REPLACES an existing value, 404 when the id is unknown
//   - DELETE removes the value at the id, 404 when unknown
//
// Routes are stored as an ordered list (like Caddy's routes array) so tests
// can assert that repeated reconciles do not pile up duplicate routes
// (REQ-E9-S02-02) without a live Caddy.
package admintest

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
)

// RequestRecord is one observed admin API call.
type RequestRecord struct {
	Method string
	Path   string
	Body   map[string]any
}

// Server is a fake Caddy admin API.
type Server struct {
	mu          sync.Mutex
	httpSrv     *httptest.Server
	routes      []map[string]any // ordered, like Caddy's routes array
	log         []RequestRecord
	unavailable bool
}

// NewServer starts the fake admin API. Callers must Close() it.
func NewServer() *Server {
	s := &Server{}
	s.httpSrv = httptest.NewServer(http.HandlerFunc(s.handle))
	return s
}

// URL is the base URL of the fake admin API.
func (s *Server) URL() string { return s.httpSrv.URL }

// Close shuts the fake admin API down.
func (s *Server) Close() { s.httpSrv.Close() }

// SetUnavailable makes every subsequent request answer 503 (REQ-E9-S03-03).
func (s *Server) SetUnavailable(down bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.unavailable = down
}

// Requests returns a copy of the request log.
func (s *Server) Requests() []RequestRecord {
	s.mu.Lock()
	defer s.mu.Unlock()
	out := make([]RequestRecord, len(s.log))
	copy(out, s.log)
	return out
}

// Route returns the first stored route with the given `@id` and whether any exists.
func (s *Server) Route(id string) (map[string]any, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if i := s.indexOfLocked(id); i >= 0 {
		return s.routes[i], true
	}
	return nil, false
}

// RouteCount returns how many routes are installed — duplicates included,
// exactly like Caddy's routes array would carry them.
func (s *Server) RouteCount() int {
	s.mu.Lock()
	defer s.mu.Unlock()
	return len(s.routes)
}

// indexOfLocked returns the index of the first route carrying the `@id`.
func (s *Server) indexOfLocked(id string) int {
	for i, r := range s.routes {
		if got, _ := r["@id"].(string); got == id {
			return i
		}
	}
	return -1
}

func (s *Server) handle(w http.ResponseWriter, r *http.Request) {
	s.mu.Lock()
	defer s.mu.Unlock()

	var body map[string]any
	if r.Body != nil {
		_ = json.NewDecoder(r.Body).Decode(&body) // GETs have no body; tolerated
	}
	s.log = append(s.log, RequestRecord{Method: r.Method, Path: r.URL.Path, Body: body})

	if s.unavailable {
		http.Error(w, `{"error":"service unavailable"}`, http.StatusServiceUnavailable)
		return
	}

	switch {
	case r.Method == http.MethodGet && strings.HasPrefix(r.URL.Path, "/config"):
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{}`))

	case r.Method == http.MethodPut && strings.HasPrefix(r.URL.Path, "/id/"):
		// Real Caddy PUT semantics: create new / INSERT — never replace.
		// Against an existing array element id this inserts a duplicate
		// right at that position; unknown id → error like real Caddy.
		id := strings.TrimPrefix(r.URL.Path, "/id/")
		i := s.indexOfLocked(id)
		if i < 0 {
			http.Error(w, `{"error":"unknown object id"}`, http.StatusNotFound)
			return
		}
		s.routes = append(s.routes[:i+1], s.routes[i:]...)
		s.routes[i] = body
		w.WriteHeader(http.StatusOK)

	case r.Method == http.MethodPatch && strings.HasPrefix(r.URL.Path, "/id/"):
		// Real Caddy PATCH semantics: strict replace of an EXISTING value.
		id := strings.TrimPrefix(r.URL.Path, "/id/")
		i := s.indexOfLocked(id)
		if i < 0 {
			http.Error(w, `{"error":"unknown object id"}`, http.StatusNotFound)
			return
		}
		s.routes[i] = body
		w.WriteHeader(http.StatusOK)

	case r.Method == http.MethodDelete && strings.HasPrefix(r.URL.Path, "/id/"):
		id := strings.TrimPrefix(r.URL.Path, "/id/")
		i := s.indexOfLocked(id)
		if i < 0 {
			http.Error(w, `{"error":"unknown object id"}`, http.StatusNotFound)
			return
		}
		s.routes = append(s.routes[:i], s.routes[i+1:]...)
		w.WriteHeader(http.StatusOK)

	case r.Method == http.MethodPost && strings.HasSuffix(r.URL.Path, "/routes"):
		// Real Caddy POST-to-array semantics: APPEND, even if a route with
		// the same @id is already installed (that is how duplicates happen).
		if id, _ := body["@id"].(string); id == "" {
			http.Error(w, `{"error":"route without @id"}`, http.StatusBadRequest)
			return
		}
		s.routes = append(s.routes, body)
		w.WriteHeader(http.StatusOK)

	default:
		http.Error(w, `{"error":"unsupported path"}`, http.StatusNotFound)
	}
}
