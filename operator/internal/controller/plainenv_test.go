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

package controller

// Envtest bootstrap for the plain (non-Ginkgo) REQ tests, so that the
// spec Verify commands like
//   go test ./internal/controller/... -run TestCaddy_Reconcile_Ready
// run self-contained without the Ginkgo suite.

import (
	"path/filepath"
	"testing"

	"k8s.io/apimachinery/pkg/runtime"
	clientgoscheme "k8s.io/client-go/kubernetes/scheme"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/envtest"

	gatewayv1alpha1 "github.com/PlatformRelay/Kaddy/operator/api/v1alpha1"
)

// Shared fixture identifiers (mirroring the design.md sample) used across
// the controller test files.
const (
	testNS        = "default"
	testCaddyName = "edge"
	testSiteName  = "clubhouse"
	testHost      = "demo.example.com"
)

// startPlainEnv boots an isolated envtest control plane with the project
// CRDs installed and returns a client against it. Stopped via t.Cleanup.
func startPlainEnv(t *testing.T) client.Client {
	t.Helper()

	env := &envtest.Environment{
		CRDDirectoryPaths: []string{
			filepath.Join("..", "..", "config", "crd", "bases"),
			filepath.Join("..", "..", "config", "crd", "testdata", "monitoring"),
		},
		ErrorIfCRDPathMissing: true,
	}
	if dir := getFirstFoundEnvTestBinaryDir(); dir != "" {
		env.BinaryAssetsDirectory = dir
	}

	cfg, err := env.Start()
	if err != nil {
		t.Fatalf("start envtest: %v", err)
	}
	t.Cleanup(func() {
		if stopErr := env.Stop(); stopErr != nil {
			t.Errorf("stop envtest: %v", stopErr)
		}
	})

	sch := runtime.NewScheme()
	if err := clientgoscheme.AddToScheme(sch); err != nil {
		t.Fatalf("add client-go scheme: %v", err)
	}
	if err := gatewayv1alpha1.AddToScheme(sch); err != nil {
		t.Fatalf("add gateway.kaddy.io scheme: %v", err)
	}

	c, err := client.New(cfg, client.Options{Scheme: sch})
	if err != nil {
		t.Fatalf("build client: %v", err)
	}
	return c
}
