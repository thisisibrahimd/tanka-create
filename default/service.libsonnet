local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.36/main.libsonnet';

{
  service:
    k.core.v1.service.new($.common.fullname, $.common.selectorLabels, [{
      name: 'http',
      port: $._config.service.port,
      targetPort: 'http',
      protocol: 'TCP',
    }]) +
    k.core.v1.service.mixin.spec.withType($._config.service.type) +
    k.core.v1.service.mixin.metadata.withLabels($.common.labels),
}
