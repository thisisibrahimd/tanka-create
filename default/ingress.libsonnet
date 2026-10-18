local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.36/main.libsonnet';

{
  ingress:
    if $._config.ingress.enabled then
      k.networking.v1.ingress.new($.common.fullname) +
      k.networking.v1.ingress.mixin.metadata.withLabels($.common.labels) +
      (if $._config.ingress.annotations != {} then
        k.networking.v1.ingress.mixin.metadata.withAnnotations($._config.ingress.annotations)
      else {}) +
      (if $._config.ingress.className != '' then
        k.networking.v1.ingress.mixin.spec.withIngressClassName($._config.ingress.className)
      else {}) +
      (if $._config.ingress.tls != [] then
        k.networking.v1.ingress.mixin.spec.withTls($._config.ingress.tls)
      else {}) +
      k.networking.v1.ingress.mixin.spec.withRules([
        {
          host: h.host,
          http: {
            paths: [
              {
                path: p.path,
                pathType: if std.objectHas(p, 'pathType') then p.pathType else 'ImplementationSpecific',
                backend: {
                  service: {
                    name: $.common.fullname,
                    port: { number: $._config.service.port },
                  },
                },
              }
              for p in h.paths
            ],
          },
        }
        for h in $._config.ingress.hosts
      ])
    else
      {},
}
