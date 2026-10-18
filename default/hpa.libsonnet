local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.36/main.libsonnet';

local metrics =
  (if $._config.autoscaling.targetCPUUtilizationPercentage != null then [{
    type: 'Resource',
    resource: {
      name: 'cpu',
      target: {
        type: 'Utilization',
        averageUtilization: $._config.autoscaling.targetCPUUtilizationPercentage,
      },
    },
  }] else []) +
  (if $._config.autoscaling.targetMemoryUtilizationPercentage != null then [{
    type: 'Resource',
    resource: {
      name: 'memory',
      target: {
        type: 'Utilization',
        averageUtilization: $._config.autoscaling.targetMemoryUtilizationPercentage,
      },
    },
  }] else []);

{
  hpa:
    if $._config.autoscaling.enabled then
      k.autoscaling.v2.horizontalPodAutoscaler.new($.common.fullname) +
      k.autoscaling.v2.horizontalPodAutoscaler.mixin.metadata.withLabels($.common.labels) +
      k.autoscaling.v2.horizontalPodAutoscaler.mixin.spec.withScaleTargetRef({
        apiVersion: 'apps/v1',
        kind: 'Deployment',
        name: $.common.fullname,
      }) +
      k.autoscaling.v2.horizontalPodAutoscaler.mixin.spec.withMinReplicas($._config.autoscaling.minReplicas) +
      k.autoscaling.v2.horizontalPodAutoscaler.mixin.spec.withMaxReplicas($._config.autoscaling.maxReplicas) +
      (if metrics != [] then
        k.autoscaling.v2.horizontalPodAutoscaler.mixin.spec.withMetrics(metrics)
      else {})
    else
      {},
}
