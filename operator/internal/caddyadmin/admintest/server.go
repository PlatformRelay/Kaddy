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
// suites: it records every request and stores routes by their `@id`, so
// tests can assert idempotency (REQ-E9-S02-02) without a live Caddy.
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
	routes      map[string]map[string]any // @id -> route object
	log         []RequestRecord
	unavailable bool
}

// NewServer starts the fake admin API. Callers must Close() it.
func NewServer() *Server {
	s := &Server{routes: map[string]map[string]any{}}
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

// Route returns the stored route for id and whether it exists.
func (s *Server) Route(id string) (map[string]any, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	r, ok := s.routes[id]
	return r, ok
}

// RouteCount returns how many distinct routes are installed.
func (s *Server) RouteCount() int {
	s.mu.Lock()
	defer s.mu.Unlock()
	return len(s.routes)
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
		id := strings.TrimPrefix(r.URL.Path, "/id/")
		if _, ok := s.routes[id]; !ok {
			http.Error(w, `{"error":"unknown object id"}`, http.StatusNotFound)
			return
		}
		s.routes[id] = body
		w.WriteHeader(http.StatusOK)

	case r.Method == http.MethodDelete && strings.HasPrefix(r.URL.Path, "/id/"):
		id := strings.TrimPrefix(r.URL.Path, "/id/")
		if _, ok := s.routes[id]; !ok {
			http.Error(w, `{"error":"unknown object id"}`, http.StatusNotFound)
			return
		}
		delete(s.routes, id)
		w.WriteHeader(http.StatusOK)

	case r.Method == http.MethodPost && strings.HasSuffix(r.URL.Path, "/routes"):
		id, _ := body["@id"].(string)
		if id == "" {
			http.Error(w, `{"error":"route without @id"}`, http.StatusBadRequest)
			return
		}
		s.routes[id] = body
		w.WriteHeader(http.StatusOK)

	default:
		http.Error(w, `{"error":"unsupported path"}`, http.StatusNotFound)
	}
}
