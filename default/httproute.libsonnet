local gw = import 'github.com/jsonnet-libs/gateway-api-libsonnet/1.5/main.libsonnet';

{
  http_route:
    if $._config.httpRoute.enabled then
      gw.gateway.v1.httpRoute.new($.common.fullname) +
      gw.gateway.v1.httpRoute.mixin.metadata.withLabels($.common.labels) +
      (if $._config.httpRoute.annotations != {} then
        gw.gateway.v1.httpRoute.mixin.metadata.withAnnotations($._config.httpRoute.annotations)
      else {}) +
      gw.gateway.v1.httpRoute.mixin.spec.withParentRefs($._config.httpRoute.parentRefs) +
      (if $._config.httpRoute.hostnames != [] then
        gw.gateway.v1.httpRoute.mixin.spec.withHostnames($._config.httpRoute.hostnames)
      else {}) +
      gw.gateway.v1.httpRoute.mixin.spec.withRules([
        {
          matches: if std.objectHas(r, 'matches') then r.matches else [],
        } +
        (if std.objectHas(r, 'filters') then { filters: r.filters } else {}) +
        {
          backendRefs: [{
            name: $.common.fullname,
            port: $._config.service.port,
            weight: 1,
          }],
        }
        for r in $._config.httpRoute.rules
      ])
    else
      {},
}
