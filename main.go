package main

import (
	"embed"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"unicode"
)

//go:embed default/*
var templateFS embed.FS

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <library-name>\n", os.Args[0])
		os.Exit(1)
	}

	tankaCreate(os.Args[1])
}

func tankaCreate(libName string) {
	name := normalizeName(libName)
	if name == "" {
		fmt.Fprintf(os.Stderr, "error: invalid library name %q\n", libName)
		os.Exit(1)
	}

	if _, err := os.Stat(name); err == nil {
		fmt.Fprintf(os.Stderr, "error: directory %q already exists\n", name)
		os.Exit(1)
	}

	if err := os.MkdirAll(name, 0o755); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	err := fs.WalkDir(templateFS, "default", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		rel := strings.TrimPrefix(path, "default/")
		if rel == "" || rel == "default" {
			return nil
		}
		if strings.HasPrefix(rel, "vendor") {
			if d.IsDir() {
				return fs.SkipDir
			}
			return nil
		}

		dst := filepath.Join(name, rel)

		// Rename default.libsonnet → <snake_case>.libsonnet
		if rel == "default.libsonnet" {
			dst = filepath.Join(name, toSnakeCase(name)+".libsonnet")
		}

		if d.IsDir() {
			return os.MkdirAll(dst, 0o755)
		}

		data, err := templateFS.ReadFile(path)
		if err != nil {
			return err
		}

		content := string(data)
		if strings.HasSuffix(path, "_library.libsonnet") {
			content = strings.Replace(content, "name: 'default'", "name: '"+name+"'", 1)
		}
		return os.WriteFile(dst, []byte(content), 0o644)
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Created %s/\n\n", name)
	fmt.Printf("To initialize the dependencies, run:\n")
	fmt.Printf("  cd %s && jb install\n", name)
}

func toSnakeCase(name string) string {
	var b strings.Builder
	for _, r := range name {
		if r == '-' || r == '_' || r == ' ' {
			b.WriteRune('_')
		} else {
			b.WriteRune(unicode.ToLower(r))
		}
	}
	result := b.String()
	for strings.Contains(result, "__") {
		result = strings.ReplaceAll(result, "__", "_")
	}
	return strings.Trim(result, "_")
}

func normalizeName(name string) string {
	var b strings.Builder
	for _, r := range name {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			b.WriteRune(unicode.ToLower(r))
		} else if r == '-' || r == '_' || r == ' ' {
			if b.Len() > 0 && b.String()[b.Len()-1] != '-' {
				b.WriteRune('-')
			}
		}
	}
	return strings.Trim(b.String(), "-")
}
