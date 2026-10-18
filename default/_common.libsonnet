local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.36/main.libsonnet';

{
  common:: {
    // Mirrors: default.name
    name::
      local base = if $._config.nameOverride != '' then $._config.nameOverride else $.library.name;
      k.util.trunc(63, base),

    // Mirrors: default.fullname
    // Tanka has no .Release.Name — environments override fullnameOverride
    fullname::
      if $._config.fullnameOverride != '' then
        k.util.trunc(63, $._config.fullnameOverride)
      else
        local base = if $._config.nameOverride != '' then $._config.nameOverride else $.library.name;
        k.util.trunc(63, '%s-%s' % [$.library.name, base]),

    // Mirrors: default.labels
    labels:: {
      'app.kubernetes.io/name': $.common.name,
      'app.kubernetes.io/instance': $.common.name,
      'app.kubernetes.io/managed-by': 'tanka',
    } + (
      if $._config.image.tag != '' then {
        'app.kubernetes.io/version': $._config.image.tag,
      } else {}
    ),

    // Mirrors: default.selectorLabels
    selectorLabels:: {
      'app.kubernetes.io/name': $.common.name,
      'app.kubernetes.io/instance': $.common.name,
    },

    // Mirrors: default.serviceAccountName
    serviceAccountName::
      if $._config.serviceAccount.create then
        if $._config.serviceAccount.name != '' then
          $._config.serviceAccount.name
        else
          $.common.fullname
      else
        if $._config.serviceAccount.name != '' then
          $._config.serviceAccount.name
        else
          $.library.name,
  },
}
