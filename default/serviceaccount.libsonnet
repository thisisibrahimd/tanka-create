local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.36/main.libsonnet';

{
  service_account:
    if $._config.serviceAccount.create then
      k.core.v1.serviceAccount.new($.common.serviceAccountName) +
      k.core.v1.serviceAccount.mixin.metadata.withLabels($.common.labels) +
      (if $._config.serviceAccount.annotations != {} then
        k.core.v1.serviceAccount.mixin.metadata.withAnnotations($._config.serviceAccount.annotations)
      else {}) +
      k.core.v1.serviceAccount.withAutomountServiceAccountToken($._config.serviceAccount.automount)
    else
      {},
}
