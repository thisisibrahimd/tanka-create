local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.36/main.libsonnet';

{
  local container = k.core.v1.container,
  local containerPort = k.core.v1.containerPort,
  local deployment = k.apps.v1.deployment,

  _container::
    container.new($.common.name, $._images.app) +
    container.withImagePullPolicy($._config.image.pullPolicy) +
    container.withPorts([{ name: 'http', containerPort: $._config.service.port, protocol: 'TCP' }]) +
    container.mixin.readinessProbe.httpGet.withPath('/') +
    container.mixin.readinessProbe.httpGet.withPort($._config.service.port) +
    container.mixin.livenessProbe.httpGet.withPath('/') +
    container.mixin.livenessProbe.httpGet.withPort($._config.service.port) +
    (if $._config.resources != {} then
      container.withResources($._config.resources)
    else {}),

  deployment:
    deployment.new($.common.fullname, $._config.replicaCount, [$._container]) +
    deployment.mixin.spec.selector.withMatchLabels($.common.selectorLabels) +
    deployment.mixin.spec.template.metadata.withLabels($.common.selectorLabels) +
    (if $._config.podAnnotations != {} then
      deployment.mixin.spec.template.metadata.withAnnotations($._config.podAnnotations)
    else {}) +
    (if $._config.podSecurityContext != {} then
      deployment.mixin.spec.template.spec.withSecurityContext($._config.podSecurityContext)
    else {}) +
    (if $._config.volumes != [] then
      deployment.mixin.spec.template.spec.withVolumes($._config.volumes)
    else {}) +
    (if $._config.nodeSelector != {} then
      deployment.mixin.spec.template.spec.withNodeSelector($._config.nodeSelector)
    else {}) +
    (if $._config.affinity != {} then
      deployment.mixin.spec.template.spec.withAffinity($._config.affinity)
    else {}) +
    (if $._config.tolerations != [] then
      deployment.mixin.spec.template.spec.withTolerations($._config.tolerations)
    else {}),
}
