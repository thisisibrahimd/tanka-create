package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"sigs.k8s.io/e2e-framework/pkg/env"
	"sigs.k8s.io/e2e-framework/pkg/envconf"
	"sigs.k8s.io/e2e-framework/pkg/envfuncs"
	"sigs.k8s.io/e2e-framework/pkg/features"
	"sigs.k8s.io/e2e-framework/support/kind"
)

var testenv env.Environment

// TestMain sets up the kind cluster before tests and tears it down after.
func TestMain(m *testing.M) {
	fmt.Printf("creating test environment\n")
	testenv = env.New()
	kindClusterName := envconf.RandomName("tanka-create", 16)
	fmt.Printf("created test environment: %s\n", kindClusterName)

	testenv.Setup(
		envfuncs.CreateCluster(kind.NewProvider(), kindClusterName),
	)

	defer func() {
		exec.Command("kind", "delete", "cluster", "--name", kindClusterName).Run()
	}()

	os.Exit(testenv.Run(m))
}

// TestTankaCreate scaffolds a library, deploys it to kind, and curls nginx.
func TestTankaCreate(t *testing.T) {
	root := repoRoot(t)

	libName := "nginx"
	t.Logf("scaffolding library: %s", libName)
	tankaCreate(libName)
	t.Cleanup(func() { os.RemoveAll(libName) })

	f := features.New("tanka-create").
		Assess("applies manifests with tk apply", func(ctx context.Context, t *testing.T, cfg *envconf.Config) context.Context {
			libDir := filepath.Join(root, libName)

			t.Logf("installing dependencies in %s", libDir)
			c := exec.Command("jb", "install")
			c.Dir = libDir
			c.Stdout = &testWriter{t}
			c.Stderr = &testWriter{t}
			if err := c.Run(); err != nil {
				t.Fatalf("command failed: jb install: %v", err)
			}

			t.Logf("creating tanka environment")
			envDir := filepath.Join(libDir, "environments", "test")
			os.MkdirAll(envDir, 0o755)

			kindCtx := runOutput(t, "kubectl", "config", "current-context")
			kindCtx = trimNL(kindCtx)

			spec := map[string]interface{}{
				"apiVersion": "tanka.dev/v1alpha1",
				"kind":       "Environment",
				"metadata":   map[string]string{"name": "test"},
				"spec": map[string]interface{}{
					"namespace":    "default",
					"contextNames": []string{kindCtx},
				},
			}
			writeJSON(t, filepath.Join(envDir, "spec.json"), spec)

			snakeName := toSnakeCase(libName)
			main := fmt.Sprintf(`import '../../%s.libsonnet'`, snakeName)
			os.WriteFile(filepath.Join(envDir, "main.jsonnet"), []byte(main), 0o644)

			t.Logf("applying manifests with tk apply")
			run(t, "tk", "apply", envDir, "--auto-approve=always")

			t.Logf("waiting for deployment to be ready")
			run(t, "kubectl", "wait",
				"--for=condition=Available", "deployment/nginx",
				"--timeout=120s")
			return ctx
		}).
		Assess("curl returns nginx welcome page", func(ctx context.Context, t *testing.T, cfg *envconf.Config) context.Context {
			t.Logf("port-forwarding service")
			cmd := exec.Command("kubectl", "port-forward", "svc/nginx", "8888:80")
			cmd.Stdout = &testWriter{t}
			cmd.Stderr = &testWriter{t}
			cmd.Start()
			defer cmd.Process.Kill()

			t.Logf("curling nginx with retry")
			retryWithBackoff(t, 5, time.Second, func() error {
				conn, err := net.DialTimeout("tcp", "localhost:8888", time.Second)
				if err != nil {
					return fmt.Errorf("port not ready: %w", err)
				}
				conn.Close()

				resp := runOutput(t, "curl", "-s", "http://localhost:8888/")
				if !strings.Contains(resp, "Welcome to nginx!") {
					return fmt.Errorf("missing \"Welcome to nginx!\" in response \nresponse:\n%s\n", resp)
				}
				return nil
			})
			return ctx
		}).
		Feature()

	testenv.Test(t, f)
}

// --- helpers below ---

func repoRoot(t *testing.T) string {
	t.Helper()
	dir, _ := os.Getwd()
	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			t.Fatal("go.mod not found")
		}
		dir = parent
	}
}

func run(t *testing.T, cmd string, args ...string) {
	t.Helper()
	c := exec.Command(cmd, args...)
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	if err := c.Run(); err != nil {
		t.Fatalf("command failed: %s %v: %v", cmd, args, err)
	}
}

func runOutput(t *testing.T, cmd string, args ...string) string {
	t.Helper()
	c := exec.Command(cmd, args...)
	out, err := c.Output()
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			t.Fatalf("command failed: %s %v: %s", cmd, args, string(exitErr.Stderr))
		}
		t.Fatalf("command failed: %s %v: %v", cmd, args, err)
	}
	return string(out)
}

func readGolden(t *testing.T) string {
	t.Helper()
	root := repoRoot(t)
	data, err := os.ReadFile(filepath.Join(root, "test", "golden", "nginx-welcome.txt"))
	if err != nil {
		t.Fatalf("failed to read golden file: %v", err)
	}
	return string(data)
}

func writeJSON(t *testing.T, path string, v interface{}) {
	t.Helper()
	data, _ := json.MarshalIndent(v, "", "  ")
	os.WriteFile(path, append(data, '\n'), 0o644)
}

func retryWithBackoff(t *testing.T, maxRetries int, initialDelay time.Duration, fn func() error) {
	t.Helper()
	delay := initialDelay
	for i := 0; i < maxRetries; i++ {
		err := fn()
		if err == nil {
			return
		}
		t.Logf("attempt %d failed: %v, retrying in %v", i+1, err, delay)
		time.Sleep(delay)
		delay *= 2
	}
	t.Fatalf("operation failed after %d retries", maxRetries)
}

func trimNL(s string) string {
	return strings.TrimSpace(s)
}

// testWriter implements io.Writer to redirect output to t.Log
type testWriter struct{ t *testing.T }

func (w *testWriter) Write(p []byte) (int, error) {
	w.t.Log(string(p))
	return len(p), nil
}
