# tanka-create

[![Release](https://img.shields.io/github/v/release/thisisibrahimd/tanka-create?label=latest)](https://github.com/thisisibrahimd/tanka-create/releases/latest)
[![Test](https://github.com/thisisibrahimd/tanka-create/actions/workflows/test.yml/badge.svg)](https://github.com/thisisibrahimd/tanka-create/actions/workflows/test.yml)

Scaffold libsonnet libraries for [Tanka](https://tanka.dev) deployment. Mirrors the
helpers and resource of a default Helm chart (deployment, service, service account,
HPA, ingress, HTTPRoute) from ```helm create```.

## Install

### Go

```sh
go install github.com/thisisibrahimd/tanka-create@latest
```

### [mise](https://mise.jdx.dev/)

```sh
mise use github:thisisibrahimd/tanka-create
```

### GitHub Releases

Download binaries from [github releases](https://github.com/thisisibrahimd/tanka-create/releases/latest).

## Usage

1. Scaffold a library

```sh
tanka-create my-app
```

2. Initialize dependencies

```sh
cd my-app && jb install
```

Your library is now ready to be imported by your tanka environment

## Scaffolded Library Layout

Mirrors the defaults provided by `helm create`:

```
my-app/
├── my_app.libsonnet                # entry point (imports all components)
├── _library.libsonnet              # library metadata replacer of Chart.yaml
├── _config.libsonnet               # configurable values (image, ports, replicas) replacer of values.yaml
├── _common.libsonnet               # shared helpers (fullname, labels, selectors)
├── _images.libsonnet               # image digest/tag resolution
├── deployment.libsonnet            # Deployment + probes
├── service.libsonnet               # Service
├── serviceaccount.libsonnet        # ServiceAccount
├── hpa.libsonnet                   # HorizontalPodAutoscaler
├── ingress.libsonnet               # Ingress
├── httproute.libsonnet             # Gateway API HTTPRoute
├── jsonnetfile.json                # dependencies
├── jsonnetfile.lock.json
└── vendor/                         # after jb install
```

The library depends on `k8s-libsonnet` 1.36 and `gateway-api-libsonnet` 1.5,
pulled automatically by `jb install`.
